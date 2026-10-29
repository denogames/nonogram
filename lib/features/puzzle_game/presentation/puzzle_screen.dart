import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
import '../../../core/monetization/ads/ad_manager.dart';
import '../../../core/monetization/economy/economy_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/storage/vault/game_state_vault.dart';
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
  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(0);
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
    _timerNotifier.dispose();
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

    final maxMistakes = StudioSdk.isInitialized
        ? StudioSdk.instance.liveOps.getBalanceValue<int>('max_mistakes_allowed', defaultValue: 3)
        : 3;

    final engine = PuzzleEngine(
      puzzle: puzzle,
      mistakePolicy: mistakePolicy,
      maxMistakesAllowed: maxMistakes,
    );

    // 1. Check crash-safe GameStateVault first, then SQLite fallback
    final vault = GameStateVault.instance;
    final vaultState = vault.isInitialized ? vault.getPuzzleState(puzzle.id) : null;

    if (vaultState != null && !vaultState.isCompleted && vaultState.savedBoardState != null) {
      engine.restoreSession(
        encodedBoard: vaultState.savedBoardState!,
        mistakes: vaultState.savedMistakes,
        hintsUsed: vaultState.savedHintsUsed,
        elapsedSeconds: vaultState.savedElapsedSeconds,
      );
    } else {
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
    }

    if (mounted) {
      _timerNotifier.value = engine.elapsedSeconds;
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
        _engine!.tickTimer();
        // Restrict re-renders strictly to leaf timer badge
        _timerNotifier.value = _engine!.elapsedSeconds;
      }
    });
  }

  Future<void> _saveProgressIfUnfinished() async {
    if (_engine == null || _puzzle == null || _engine!.isCompleted) return;

    final boardStr = _engine!.serializeBoardState();
    final now = DateTime.now();

    // 1. Persist to crash-safe vault
    final vault = GameStateVault.instance;
    if (vault.isInitialized) {
      await vault.savePuzzleState(
        SavedPuzzleState(
          puzzleId: _puzzle!.id,
          isCompleted: false,
          stars: 0,
          bestTimeSeconds: 0,
          lastPlayed: now,
          savedBoardState: boardStr,
          savedMistakes: _engine!.mistakes,
          savedHintsUsed: _engine!.hintsUsed,
          savedElapsedSeconds: _engine!.elapsedSeconds,
        ),
      );
    }

    // 2. Persist to SQLite
    final db = ref.read(databaseProvider);
    await db.saveProgress(
      PuzzleProgressEntriesCompanion(
        puzzleId: drift.Value(_puzzle!.id),
        isCompleted: const drift.Value(false),
        lastPlayed: drift.Value(now),
        savedBoardState: drift.Value(boardStr),
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
    final now = DateTime.now();

    // 2. Persist completion to crash-safe vault
    final vault = GameStateVault.instance;
    if (vault.isInitialized) {
      await vault.savePuzzleState(
        SavedPuzzleState(
          puzzleId: _puzzle!.id,
          isCompleted: true,
          stars: stars,
          bestTimeSeconds: _engine!.elapsedSeconds,
          lastPlayed: now,
          savedBoardState: null,
        ),
      );
    }

    // 3. Persist completion in DB
    await db.saveProgress(
      PuzzleProgressEntriesCompanion(
        puzzleId: drift.Value(_puzzle!.id),
        isCompleted: const drift.Value(true),
        stars: drift.Value(stars),
        bestTimeSeconds: drift.Value(_engine!.elapsedSeconds),
        lastPlayed: drift.Value(now),
        savedBoardState: const drift.Value(null),
      ),
    );

    // If Daily, record daily entry
    if (widget.isDaily) {
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

    // 4. Grant Gameplay Coins via Single-Source Wallet
    final economy = ref.read(economyManagerProvider);
    final earnedCoins = stars * 15;
    await economy.grantReward(addCoins: earnedCoins);

    await analytics.logPuzzleCompleted(
      puzzleId: _puzzle!.id,
      elapsedSeconds: _engine!.elapsedSeconds,
      mistakes: mistakes,
      hintsUsed: hints,
      isDaily: widget.isDaily,
    );

    // 5. Natural Interstitial Ad check
    await adManager.maybeShowCompletionInterstitial();

    // 6. Studio Core SDK Outbox Integration (offline-safe)
    if (StudioSdk.isInitialized) {
      final sdk = StudioSdk.instance;
      unawaited(
        sdk.outboxSync.enqueueMutation(
          type: OutboxOperationType.levelProgression,
          payload: {
            'puzzleId': _puzzle!.id,
            'category': _puzzle!.category,
            'stars': stars,
            'elapsedSeconds': _engine!.elapsedSeconds,
            'mistakes': mistakes,
            'hintsUsed': hints,
            'isDaily': widget.isDaily,
            'completedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Ad mediation interstitial check
      unawaited(sdk.adMediation.showInterstitialIfEligible(placement: 'puzzle_complete'));
    }

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
    } else if (_engine != null && _engine!.isFailed) {
      _handlePuzzleFailed();
    }
  }

  void _handlePuzzleFailed() {
    _timer?.cancel();
    if (StudioSdk.isInitialized) {
      final totalCells = _puzzle!.width * _puzzle!.height;
      final filledCells = _engine!.board.expand((r) => r).where((c) => c != CellState.empty).length;
      final ratio = totalCells > 0 ? (filledCells / totalCells).clamp(0.0, 1.0) : 0.5;

      unawaited(
        StudioSdk.instance.pinchPoint.evaluateGameContext(
          depletedCurrencyId: StudioCurrencyIds.lives,
          levelCompletionRatio: ratio,
          consecutiveFailures: 1,
        ),
      );
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
      // Trigger RFM dynamic pinch-point rescue evaluation
      if (StudioSdk.isInitialized) {
        final totalCells = _puzzle!.width * _puzzle!.height;
        final filledCells = _engine!.board.expand((r) => r).where((c) => c != CellState.empty).length;
        final ratio = totalCells > 0 ? (filledCells / totalCells).clamp(0.0, 1.0) : 0.8;

        unawaited(
          StudioSdk.instance.pinchPoint.evaluateGameContext(
            depletedCurrencyId: StudioCurrencyIds.hints,
            levelCompletionRatio: ratio,
            consecutiveFailures: _engine!.isFailed ? 1 : 0,
          ),
        );
      }
      _showOutOfHintsDialog(economy, adManager);
    }
  }

  void _showOutOfHintsDialog(EconomyManager economy, AdManager adManager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Get More Hints'),
        content: Text(
          'You have 0 hints left. You have ${economy.coins} coins.\n\nExchange coins for hints below:',
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
          // Leaf-only Timer Chip (zero full-screen repaints)
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
                  ValueListenableBuilder<int>(
                    valueListenable: _timerNotifier,
                    builder: (context, seconds, _) => Text(
                      _formatTimer(seconds),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
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
                _timerNotifier.value = 0;
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
                  _timerNotifier.value = 0;
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
