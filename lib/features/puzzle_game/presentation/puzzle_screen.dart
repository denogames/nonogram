import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
import '../../../core/monetization/ads/ad_manager.dart';
import '../../../core/monetization/economy/economy_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/completion_record.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/storage/puzzle_autosave.dart';
import '../../../core/storage/saved_board.dart';
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

  /// Saves the unfinished attempt after every change (N-1). Disabled until the puzzle is
  /// loaded, and for a puzzle completed before (a replay never overwrites its completion).
  PuzzleAutosave _autosave = PuzzleAutosave((_) async {}, enabled: false);
  AppLifecycleListener? _lifecycle;

  /// The attempt whose completion is being or was recorded: a duplicate callback for the same
  /// attempt does nothing (a replay from the dialog is a new attempt).
  PuzzleEngine? _completionHandledFor;

  @override
  void initState() {
    super.initState();
    // Leaving the foreground flushes the newest state, with the current elapsed time.
    _lifecycle = AppLifecycleListener(onStateChange: (state) {
      if (state != AppLifecycleState.resumed) _saveNow(flush: true);
    });
    _loadPuzzleAndSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    _timerNotifier.dispose();
    _saveNow(flush: true);
    super.dispose();
  }

  /// Queues the current unfinished board (no-op once completed, or for a replay).
  void _saveNow({bool flush = false}) {
    final engine = _engine;
    final puzzle = _puzzle;
    if (engine == null || puzzle == null || engine.isCompleted) return;
    _autosave.save(UnfinishedAttempt.of(
      puzzle,
      cells: engine.serializeBoardState(),
      mistakes: engine.mistakes,
      hintsUsed: engine.hintsUsed,
      elapsedSeconds: engine.elapsedSeconds,
    ));
    if (flush) unawaited(_autosave.flush());
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

    // 1. Resume an unfinished attempt (crash-safe vault first, then SQLite), only when it was
    //    saved on this puzzle's current content (see SavedBoard).
    final vault = GameStateVault.instance;
    final database = ref.read(databaseProvider);
    final vaultState = vault.isInitialized ? vault.getPuzzleState(puzzle.id) : null;
    final databaseRow = await database.getProgress(puzzle.id);
    final completedBefore = CompletionRecords.wasCompleted(vaultState, databaseRow);
    // A completed puzzle always opens as a fresh replay; an unfinished attempt left by an
    // earlier version on a completed puzzle is not resumed.
    final attempt = completedBefore
        ? null
        : ResumableAttempt.choose(
            puzzle,
            vault: vaultState,
            database: databaseRow,
          );
    if (attempt != null) {
      engine.restoreSession(
        encodedBoard: attempt.cells,
        mistakes: attempt.mistakes,
        hintsUsed: attempt.hintsUsed,
        elapsedSeconds: attempt.elapsedSeconds,
      );
    }

    if (mounted) {
      _autosave = PuzzleAutosave(
        (a) => UnfinishedAttempt.writeTo(a, vault: vault, database: database),
        enabled: !completedBefore,
      );
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

  Future<void> _handlePuzzleCompletion() async {
    final engine = _engine;
    if (engine == null || identical(_completionHandledFor, engine)) return;
    _completionHandledFor = engine;
    _timer?.cancel();
    // No unfinished snapshot may be written after the completion record.
    await _autosave.close();

    final db = ref.read(databaseProvider);
    final analytics = ref.read(analyticsProvider);
    final adManager = ref.read(adManagerProvider);

    // 1. Calculate Stars
    final mistakes = engine.mistakes;
    final hints = engine.hintsUsed;
    final stars = (mistakes == 0 && hints == 0) ? 3 : (mistakes <= 1 && hints <= 2 ? 2 : 1);
    final now = DateTime.now();

    // 2-3. Completion record (vault + DB): never reverts, keeps the best stars and time, and
    //      says whether this is the first completion. Written before any coin is credited.
    final outcome = await CompletionRecords.record(
      puzzleId: _puzzle!.id,
      stars: stars,
      timeSeconds: engine.elapsedSeconds,
      vault: GameStateVault.instance,
      database: db,
      at: now,
    );

    // If Daily, record daily entry
    if (widget.isDaily) {
      final dateKey = '${now.year}-${now.month}-${now.day}';
      // One record per date: a replay keeps the first completion time and only improves the time.
      final existing = await db.getDaily(dateKey);
      final time = engine.elapsedSeconds;
      if (existing != null && existing.isCompleted) {
        if (existing.timeSeconds <= 0 || time < existing.timeSeconds) {
          await (db.update(db.dailyPuzzleEntries)..where((t) => t.dateKey.equals(dateKey)))
              .write(DailyPuzzleEntriesCompanion(timeSeconds: drift.Value(time)));
        }
      } else {
        await db.saveDaily(
          DailyPuzzleEntriesCompanion(
            dateKey: drift.Value(dateKey),
            puzzleId: drift.Value(_puzzle!.id),
            isCompleted: const drift.Value(true),
            timeSeconds: drift.Value(time),
            completedAt: drift.Value(DateTime.now()),
          ),
        );
      }
      await analytics.logDailyChallengeCompleted(
        dateKey: dateKey,
        elapsedSeconds: _engine!.elapsedSeconds,
      );
    }

    // 4. Gameplay coins via the single-source wallet: first completion only (stars × 15).
    if (outcome.firstCompletion) {
      await ref.read(economyManagerProvider).grantReward(addCoins: stars * 15);
    }

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
            'bestStars': outcome.bestStars,
            'firstCompletion': outcome.firstCompletion,
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
      return;
    }
    _saveNow();
    if (_engine != null && _engine!.isFailed) {
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
              _saveNow(); // a restart replaces the saved board too
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
