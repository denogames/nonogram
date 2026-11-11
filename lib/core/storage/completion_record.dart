import 'dart:async';

import 'package:drift/drift.dart' as drift;

import 'database/app_database.dart';
import 'vault/game_state_vault.dart';

/// What recording a completion did.
class CompletionOutcome {
  /// True only for the first completion ever recorded for the puzzle: the one that pays coins.
  final bool firstCompletion;

  /// Best results now stored (the highest stars, the fastest valid time).
  final int bestStars;
  final int bestTimeSeconds;

  const CompletionOutcome({required this.firstCompletion, required this.bestStars, required this.bestTimeSeconds});
}

/// The completion record of a puzzle (crash-safe vault plus SQLite) and the rule that its
/// coin reward is paid once (N-2, decision D-010).
///
/// - The record is written **before** coins are credited and says whether this was the first
///   completion; a duplicate callback, a second screen or a later replay finds it and pays
///   nothing. An interruption between the two writes can lose that one reward, never pay it
///   twice.
/// - Completion never reverts; stars keep the highest value, time the fastest valid one.
class CompletionRecords {
  CompletionRecords._();

  static final Map<String, Future<void>> _queues = {};

  /// Whether [puzzleId] was completed before, from any trace of a completion. Rows written by
  /// earlier versions may say `isCompleted: false` after a replay but still carry stars or a
  /// best time, which only a completion writes.
  static bool wasCompleted(SavedPuzzleState? vault, PuzzleProgressEntry? database) =>
      (vault?.isCompleted ?? false) ||
      (database?.isCompleted ?? false) ||
      (vault?.stars ?? 0) > 0 ||
      (vault?.bestTimeSeconds ?? 0) > 0 ||
      (database?.stars ?? 0) > 0 ||
      (database?.bestTimeSeconds ?? 0) > 0;

  /// Records a completion of [puzzleId] with [stars] in [timeSeconds]. Calls for the same
  /// puzzle run one after another, so concurrent completions see each other.
  static Future<CompletionOutcome> record({
    required String puzzleId,
    required int stars,
    required int timeSeconds,
    required GameStateVault vault,
    required AppDatabase database,
    DateTime? at,
  }) {
    final previous = _queues[puzzleId] ?? Future<void>.value();
    final result = previous.then((_) => _record(puzzleId, stars, timeSeconds, vault, database, at ?? DateTime.now()));
    final settled = result.then((_) {}, onError: (_) {});
    _queues[puzzleId] = settled;
    unawaited(settled.then((_) {
      if (identical(_queues[puzzleId], settled)) _queues.remove(puzzleId);
    }));
    return result;
  }

  static Future<CompletionOutcome> _record(
    String puzzleId,
    int stars,
    int timeSeconds,
    GameStateVault vault,
    AppDatabase database,
    DateTime at,
  ) async {
    final storedVault = vault.isInitialized ? vault.getPuzzleState(puzzleId) : null;
    final storedRow = await database.getProgress(puzzleId);
    final first = !wasCompleted(storedVault, storedRow);

    var bestStars = stars;
    for (final s in [storedVault?.stars ?? 0, storedRow?.stars ?? 0]) {
      if (s > bestStars) bestStars = s;
    }
    var bestTime = timeSeconds > 0 ? timeSeconds : 0;
    for (final t in [storedVault?.bestTimeSeconds ?? 0, storedRow?.bestTimeSeconds ?? 0]) {
      if (t > 0 && (bestTime == 0 || t < bestTime)) bestTime = t;
    }

    if (vault.isInitialized) {
      await vault.savePuzzleState(SavedPuzzleState(
        puzzleId: puzzleId,
        isCompleted: true,
        stars: bestStars,
        bestTimeSeconds: bestTime,
        lastPlayed: at,
        savedBoardState: null,
      ));
    }
    await database.saveProgress(PuzzleProgressEntriesCompanion(
      puzzleId: drift.Value(puzzleId),
      isCompleted: const drift.Value(true),
      stars: drift.Value(bestStars),
      bestTimeSeconds: drift.Value(bestTime),
      lastPlayed: drift.Value(at),
      savedBoardState: const drift.Value(null),
    ));
    return CompletionOutcome(firstCompletion: first, bestStars: bestStars, bestTimeSeconds: bestTime);
  }
}
