import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../engine/models/puzzle_definition.dart';
import 'database/app_database.dart';
import 'saved_board.dart';
import 'vault/game_state_vault.dart';

/// An unfinished attempt as it stood after one change. Captured synchronously, so a later
/// move can never alter a snapshot that is waiting to be written.
@immutable
class UnfinishedAttempt {
  final String puzzleId;

  /// The board in [SavedBoard] format (`fp1:<content fingerprint>:<cells>`).
  final String savedBoard;
  final int mistakes;
  final int hintsUsed;
  final int elapsedSeconds;
  final DateTime savedAt;

  const UnfinishedAttempt({
    required this.puzzleId,
    required this.savedBoard,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsedSeconds,
    required this.savedAt,
  });

  factory UnfinishedAttempt.of(
    PuzzleDefinition puzzle, {
    required String cells,
    required int mistakes,
    required int hintsUsed,
    required int elapsedSeconds,
    DateTime? at,
  }) =>
      UnfinishedAttempt(
        puzzleId: puzzle.id,
        savedBoard: SavedBoard.encode(puzzle, cells),
        mistakes: mistakes,
        hintsUsed: hintsUsed,
        elapsedSeconds: elapsedSeconds,
        savedAt: at ?? DateTime.now(),
      );

  /// Writes the attempt the way the game always stored unfinished boards: the crash-safe vault
  /// first, then SQLite. [ResumableAttempt.choose] reads them back in that order.
  static Future<void> writeTo(UnfinishedAttempt a, {required GameStateVault vault, required AppDatabase database}) async {
    if (vault.isInitialized) {
      await vault.savePuzzleState(
        SavedPuzzleState(
          puzzleId: a.puzzleId,
          isCompleted: false,
          stars: 0,
          bestTimeSeconds: 0,
          lastPlayed: a.savedAt,
          savedBoardState: a.savedBoard,
          savedMistakes: a.mistakes,
          savedHintsUsed: a.hintsUsed,
          savedElapsedSeconds: a.elapsedSeconds,
        ),
      );
    }
    await database.saveProgress(
      PuzzleProgressEntriesCompanion(
        puzzleId: drift.Value(a.puzzleId),
        isCompleted: const drift.Value(false),
        lastPlayed: drift.Value(a.savedAt),
        savedBoardState: drift.Value(a.savedBoard),
        savedMistakes: drift.Value(a.mistakes),
        savedHintsUsed: drift.Value(a.hintsUsed),
        savedElapsedSeconds: drift.Value(a.elapsedSeconds),
      ),
    );
  }
}

/// Saves an unfinished puzzle after every change, without waiting for the player to leave the
/// screen (N-1: a killed app used to lose the attempt).
///
/// - One write at a time, in order; while one runs, only the newest snapshot waits, so rapid
///   moves cost at most one extra write and an older board never lands after a newer one.
/// - A failed write is kept and retried with the next change or [flush]; it is never retried in
///   a loop.
/// - [close] (on completion) drops what is waiting and waits for the write in progress, so no
///   unfinished snapshot can be written after the completion record.
class PuzzleAutosave {
  PuzzleAutosave(this._write, {bool enabled = true}) : _closed = !enabled;

  final Future<void> Function(UnfinishedAttempt attempt) _write;

  UnfinishedAttempt? _waiting;
  UnfinishedAttempt? _failed;
  Future<void>? _inFlight;
  bool _closed;

  int _writes = 0;
  int _failures = 0;

  /// Completed writes and failed writes, for diagnostics and tests.
  int get writes => _writes;
  int get failures => _failures;
  bool get isClosed => _closed;
  bool get isIdle => _inFlight == null && _waiting == null;

  /// Queues [attempt] as the newest state of the puzzle and starts writing if idle.
  void save(UnfinishedAttempt attempt) {
    if (_closed) return;
    _waiting = attempt;
    _failed = null; // superseded by a newer state
    _pump();
  }

  /// Writes whatever is waiting (or last failed) and completes when nothing is in progress.
  Future<void> flush() async {
    if (!_closed && _waiting == null && _failed != null) {
      _waiting = _failed;
      _failed = null;
    }
    _pump();
    while (_inFlight != null) {
      await _inFlight;
    }
  }

  /// No more unfinished saves: drops what is waiting and waits for the write in progress.
  Future<void> close() async {
    _closed = true;
    _waiting = null;
    _failed = null;
    while (_inFlight != null) {
      await _inFlight;
    }
  }

  void _pump() {
    if (_closed || _inFlight != null || _waiting == null) return;
    final attempt = _waiting!;
    _waiting = null;
    _inFlight = _run(attempt);
  }

  Future<void> _run(UnfinishedAttempt attempt) async {
    try {
      await _write(attempt);
      _writes++;
    } catch (e) {
      _failures++;
      if (_waiting == null && !_closed) _failed = attempt;
      debugPrint('[autosave] write failed for ${attempt.puzzleId}: $e');
    } finally {
      _inFlight = null;
      _pump();
    }
  }
}
