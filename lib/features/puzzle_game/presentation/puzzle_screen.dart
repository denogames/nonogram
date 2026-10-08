import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/monetization/ads/ad_manager.dart';
import '../../../core/monetization/economy/economy_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engine/game/puzzle_engine.dart';
import '../../../engine/models/cell_state.dart';
import '../../../engine/models/puzzle_definition.dart';
import 'widgets/artwork_reveal_widget.dart';
import 'widgets/control_bar_widget.dart';
import 'widgets/precision_input_panel.dart';
import 'widgets/puzzle_board_widget.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  final String puzzleId;
  final bool isDaily;

  const PuzzleScreen({
    super.key,
    required this.puzzleId,
    this.isDaily = false,
  });

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  PuzzleDefinition? _puzzle;
  PuzzleEngine? _engine;
  Timer? _timer;
  EditTool _currentTool = EditTool.fill;
  bool _isPrecisionActive = false;
  bool _showRevealDialog = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPuzzleAndSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveProgressIfUnfinished();
    super.dispose();
  }

  Future<void> _loadPuzzleAndSession() async {
    final repo = ref.read(puzzleRepositoryProvider);
    final puzzle = repo.getPuzzleById(widget.puzzleId);

    if (puzzle == null) {
      if (mounted) context.pop();
      return;
    }

    final prefs = ref.read(preferencesProvider);
    final mistakePolicy = prefs.mistakePolicy;

    final engine = PuzzleEngine(
      puzzle: puzzle,
      mistakePolicy: mistakePolicy,
      maxMistakesAllowed: 3,
    );

    // Check if previous unfinished session is saved in SQLite
    final db = ref.read(databaseProvider);
    final savedProgress = await db.getProgress(puzzle.id);

    if (savedProgress != null && !savedProgress.isCompleted && savedProgress.savedBoardState != null) {
      engine.restoreSession(
        encodedBoard: savedProgress.savedBoardState!,
        mistakes: savedProgress.savedMistakes,
        hintsUsed: savedProgress.savedHintsUsed,
        elapsedSeconds: savedProgress.savedElapsedSeconds,
      );
    }

    if (mounted) {
      setState(() {
        _puzzle = puzzle;
        _engine = engine;
        _isLoading = false;
        _isPrecisionActive = prefs.precisionInputEnabled;
      });

      _startTimer();

      ref.read(analyticsProvider).logPuzzleStarted(
            puzzleId: puzzle.id,
            category: puzzle.category,
            width: puzzle.width,
            height: puzzle.height,
            difficulty: puzzle.difficulty.name,
          );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_engine != null && !_engine!.isCompleted && mounted) {
        setState(() {
          _engine!.tickTimer();
        });
      }
    });
  }

  Future<void> _saveProgressIfUnfinished() async {
    if (_engine == null || _puzzle == null || _engine!.isCompleted) return;

    final db = ref.read(databaseProvider);
    await db.saveProgress(
      PuzzleProgressEntriesCompanion(
        puzzleId: drift.Value(_puzzle!.id),
        isCompleted: const drift.Value(false),
        lastPlayed: drift.Value(DateTime.now()),
        savedBoardState: drift.Value(_engine!.serializeBoardState()),
        savedMistakes: drift.Value(_engine!.mistakes),
        savedHintsUsed: drift.Value(_engine!.hintsUsed),
        savedElapsedSeconds: drift.Value(_engine!.elapsedSeconds),
      ),
    );
  }

  Future<void> _handlePuzzleCompletion() async {
    _timer?.cancel();

    final db = ref.read(databaseProvider);
    final analytics = ref.read(analyticsProvider);
    final adManager = ref.read(adManagerProvider);

    // 1. Calculate Stars
    final mistakes = _engine!.mistakes;
    final hints = _engine!.hintsUsed;
    final stars = (mistakes == 0 && hints == 0) ? 3 : (mistakes <= 1 && hints <= 2 ? 2 : 1);

    // 2. Persist completion in DB
    await db.saveProgress(
      PuzzleProgressEntriesCompanion(
        puzzleId: drift.Value(_puzzle!.id),
        isCompleted: const drift.Value(true),
        stars: drift.Value(stars),
        bestTimeSeconds: drift.Value(_engine!.elapsedSeconds),
        lastPlayed: drift.Value(DateTime.now()),
        savedBoardState: const drift.Value(null), // clear saved in-progress state
      ),
    );

    // If Daily, record daily entry
    if (widget.isDaily) {
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month}-${now.day}';
      await db.saveDaily(
        DailyPuzzleEntriesCompanion(
          dateKey: drift.Value(dateKey),
          puzzleId: drift.Value(_puzzle!.id),
          isCompleted: const drift.Value(true),
          timeSeconds: drift.Value(_engine!.elapsedSeconds),
          completedAt: drift.Value(DateTime.now()),
        ),
      );
      await analytics.logDailyChallengeCompleted(
        dateKey: dateKey,
        elapsedSeconds: _engine!.elapsedSeconds,
      );
    }

    // 3. Analytics
    await analytics.logPuzzleCompleted(
      puzzleId: _puzzle!.id,
      elapsedSeconds: _engine!.elapsedSeconds,
      mistakes: mistakes,
      hintsUsed: hints,
      isDaily: widget.isDaily,
    );

    // 4. Natural Interstitial Ad check
    await adManager.maybeShowCompletionInterstitial();

    if (mounted) {
      setState(() {
        _showRevealDialog = true;
      });
    }
  }

  void _onBoardModified() {
    setState(() {});
    if (_engine != null && _engine!.isCompleted) {
      _handlePuzzleCompletion();
    }
  }

  Future<void> _onHintRequested() async {
    if (_engine == null || _engine!.isCompleted) return;

    final economy = ref.read(economyManagerProvider);
    final adManager = ref.read(adManagerProvider);

    if (economy.hintsRemaining > 0) {
      final success = await economy.consumeHint();
      if (success) {
        _engine!.provideHint();
        ref.read(analyticsProvider).logHintUsed(
              puzzleId: _puzzle!.id,
              remaining: economy.hintsRemaining,
            );
        _onBoardModified();
      }
    } else {
      // Show hint dialog to watch ad or buy with coins
      _showOutOfHintsDialog(economy, adManager);
    }
  }

  void _showOutOfHintsDialog(EconomyManager economy, AdManager adManager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Get More Hints'),
        content: Text(
          'You have 0 hints left. You have ${economy.coins} coins.\n\nChoose an option below:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (economy.coins >= 50)
            ElevatedButton.icon(
              icon: const Icon(Icons.monetization_on_rounded),
              label: const Text('Buy 1 Hint (50 Coins)'),
              onPressed: () async {
                Navigator.pop(ctx);
                await economy.buyHintWithCoins(cost: 50, hintsToAdd: 1);
                await _onHintRequested();
              },
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Free Hint (Watch Ad)'),
            onPressed: () async {
              Navigator.pop(ctx);
              final earned = await adManager.showRewardedForHint();
              if (earned) {
                await economy.grantReward(addHints: 1);
                await _onHintRequested();
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);

    if (_isLoading || _engine == null || _puzzle == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final economy = ref.watch(economyManagerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              _puzzle!.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${_puzzle!.width}×${_puzzle!.height} • ${_puzzle!.difficulty.displayName}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Timer Chip
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.clueBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimer(_engine!.elapsedSeconds),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Restart button
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Restart Puzzle',
            onPressed: () {
              setState(() {
                _engine = PuzzleEngine(
                  puzzle: _puzzle!,
                  mistakePolicy: ref.read(preferencesProvider).mistakePolicy,
                );
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Mistake counter banner (if strict policy)
              if (_engine!.mistakePolicy == MistakePolicy.strict)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: colors.clueBackground,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Mistakes: ', style: TextStyle(fontSize: 13)),
                      Row(
                        children: List.generate(3, (i) {
                          final isMistake = i < _engine!.mistakes;
                          return Icon(
                            isMistake ? Icons.close_rounded : Icons.favorite_rounded,
                            size: 16,
                            color: isMistake ? Colors.red : Colors.pinkAccent,
                          );
                        }),
                      ),
                    ],
                  ),
                ),

              // Interactive Nonogram Grid Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PuzzleBoardWidget(
                    engine: _engine!,
                    colors: colors,
                    currentTool: _currentTool,
                    isPrecisionMode: _isPrecisionActive,
                    onBoardModified: _onBoardModified,
                  ),
                ),
              ),

              // Optional Precision Input Panel
              if (_isPrecisionActive)
                PrecisionInputPanel(
                  engine: _engine!,
                  colors: colors,
                  currentTool: _currentTool,
                  onModified: _onBoardModified,
                ),

              // Bottom Control Bar
              ControlBarWidget(
                currentTool: _currentTool,
                onToolChanged: (tool) => setState(() => _currentTool = tool),
                canUndo: _engine!.canUndo,
                canRedo: _engine!.canRedo,
                onUndo: () {
                  _engine!.undo();
                  _onBoardModified();
                },
                onRedo: () {
                  _engine!.redo();
                  _onBoardModified();
                },
                onHint: _onHintRequested,
                hintsRemaining: economy.hintsRemaining,
                isPrecisionActive: _isPrecisionActive,
                onTogglePrecision: () {
                  setState(() => _isPrecisionActive = !_isPrecisionActive);
                },
                colors: colors,
              ),
            ],
          ),

          // Completion Celebration Modal Overlay
          if (_showRevealDialog)
            ArtworkRevealDialog(
              puzzle: _puzzle!,
              elapsedSeconds: _engine!.elapsedSeconds,
              mistakes: _engine!.mistakes,
              hintsUsed: _engine!.hintsUsed,
              colors: colors,
              onNextPuzzle: () {
                final repo = ref.read(puzzleRepositoryProvider);
                final catPuzzles = repo.getPuzzlesForCategory(_puzzle!.category);
                final currentIndex = catPuzzles.indexWhere((p) => p.id == _puzzle!.id);
                if (currentIndex >= 0 && currentIndex + 1 < catPuzzles.length) {
                  final nextPuzzle = catPuzzles[currentIndex + 1];
                  context.pushReplacement('/puzzle/${nextPuzzle.id}');
                } else {
                  context.pop();
                }
              },
              onReplay: () {
                setState(() {
                  _showRevealDialog = false;
                  _engine = PuzzleEngine(
                    puzzle: _puzzle!,
                    mistakePolicy: ref.read(preferencesProvider).mistakePolicy,
                  );
                  _startTimer();
                });
              },
              onExit: () => context.pop(),
            ),
        ],
      ),
    );
  }
}
