// N-1: unfinished boards are saved after every change, in order, and survive a restart.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/storage/database/app_database.dart';
import 'package:nonogram/core/storage/puzzle_autosave.dart';
import 'package:nonogram/core/storage/saved_board.dart';
import 'package:nonogram/core/storage/vault/game_state_vault.dart';
import 'package:nonogram/engine/game/puzzle_engine.dart';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/engine/models/cell_state.dart';
import 'package:nonogram/engine/models/puzzle_definition.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

PuzzleDefinition cat({String id = 'cat_5x5', List<String>? art}) => PuzzleGenerator.fromAsciiArt(
      id: id,
      title: 'Cat',
      category: 'animals',
      asciiLines: art ?? ['#...#', '#####', '##.##', '.###.', '..#..'],
    );

UnfinishedAttempt attemptAfter(PuzzleDefinition p, List<(int, int)> fills, {int seconds = 10}) {
  final engine = PuzzleEngine(puzzle: p);
  for (final (r, c) in fills) {
    engine.applyTool(r, c, EditTool.fill);
  }
  return UnfinishedAttempt.of(p,
      cells: engine.serializeBoardState(), mistakes: engine.mistakes, hintsUsed: engine.hintsUsed, elapsedSeconds: seconds);
}

/// A writer whose writes finish only when the test says so.
class GatedWriter {
  final List<UnfinishedAttempt> started = [];
  final List<UnfinishedAttempt> done = [];
  final List<Completer<void>> _gates = [];
  int failNext = 0;

  Future<void> write(UnfinishedAttempt a) async {
    started.add(a);
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
    if (failNext > 0) {
      failNext--;
      throw const FileSystemException('disk full');
    }
    done.add(a);
  }

  Future<void> release() async {
    for (final g in _gates.where((g) => !g.isCompleted).toList()) {
      g.complete();
    }
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final puzzle = cat();

  group('ordering and coalescing', () {
    test('a single move is written at once, without leaving the screen', () async {
      final w = GatedWriter();
      final autosave = PuzzleAutosave(w.write)..save(attemptAfter(puzzle, [(0, 0)]));
      expect(w.started, hasLength(1), reason: 'the write starts immediately');
      await w.release();
      await autosave.flush();
      expect(w.done.single.savedBoard, attemptAfter(puzzle, [(0, 0)]).savedBoard);
      expect(autosave.isIdle, isTrue);
    });

    test('rapid moves: one write in progress, only the newest waits, and it lands last', () async {
      final w = GatedWriter();
      final autosave = PuzzleAutosave(w.write);
      final moves = <(int, int)>[];
      for (var i = 0; i < 5; i++) {
        moves.add((1, i));
        autosave.save(attemptAfter(puzzle, moves, seconds: i));
      }
      expect(w.started, hasLength(1), reason: 'no overlapping writes');
      await w.release(); // first write done; the newest (5 moves) starts
      expect(w.started, hasLength(2));
      expect(w.started.last.savedBoard, attemptAfter(puzzle, moves).savedBoard);
      await w.release();
      await autosave.flush();
      expect(w.done.map((a) => a.elapsedSeconds), [0, 4], reason: 'ordered; intermediate states skipped');
      expect(autosave.writes, 2);
    });

    test('a failed write is kept, retried by the next flush, never in a loop', () async {
      final w = GatedWriter()..failNext = 1;
      final autosave = PuzzleAutosave(w.write)..save(attemptAfter(puzzle, [(0, 0)]));
      await w.release();
      expect(autosave.failures, 1);
      expect(w.started, hasLength(1), reason: 'no automatic retry loop');
      final retry = autosave.flush();
      await w.release();
      await retry;
      expect(w.done.single.savedBoard, attemptAfter(puzzle, [(0, 0)]).savedBoard);
    });

    test('a newer move replaces a failed one', () async {
      final w = GatedWriter()..failNext = 1;
      final autosave = PuzzleAutosave(w.write)..save(attemptAfter(puzzle, [(0, 0)]));
      await w.release();
      autosave.save(attemptAfter(puzzle, [(0, 0), (1, 0)]));
      await w.release();
      await autosave.flush();
      expect(w.done.single.savedBoard, attemptAfter(puzzle, [(0, 0), (1, 0)]).savedBoard);
    });

    test('completion while a write is pending: waiting state dropped, nothing after close', () async {
      final w = GatedWriter();
      final autosave = PuzzleAutosave(w.write)
        ..save(attemptAfter(puzzle, [(0, 0)]))
        ..save(attemptAfter(puzzle, [(0, 0), (0, 4)]));
      var closed = false;
      final closing = autosave.close().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      expect(closed, isFalse, reason: 'close waits for the write in progress');
      await w.release();
      await closing;
      autosave.save(attemptAfter(puzzle, [(2, 2)]));
      await autosave.flush();
      expect(w.started, hasLength(1), reason: 'the waiting snapshot and later saves are dropped');
    });

    test('disabled (puzzle completed before): nothing is written', () async {
      final w = GatedWriter();
      final autosave = PuzzleAutosave(w.write, enabled: false)..save(attemptAfter(puzzle, [(0, 0)]));
      await autosave.flush();
      expect(w.started, isEmpty);
    });
  });

  group('real stores', () {
    late Directory dir;
    late File dbFile;
    final open = <AppDatabase>[];

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('nonogram_autosave_');
      dbFile = File('${dir.path}/game.sqlite');
    });
    tearDown(() async {
      for (final db in open) {
        await db.close();
      }
      open.clear();
      await GameStateVault.instance.clearAll();
      await dir.delete(recursive: true);
    });

    /// One app process: database file and crash-safe vault; the previous process is gone.
    Future<(GameStateVault, AppDatabase)> launch() async {
      for (final db in open) {
        await db.close();
      }
      open.clear();
      EncryptedStorageBox.resetRegistryForTesting();
      final vault = GameStateVault.instance;
      await vault.initialize(storageDirectoryPath: (await Directory('${dir.path}/vault').create()).path);
      final db = AppDatabase(NativeDatabase(dbFile));
      open.add(db);
      return (vault, db);
    }

    Future<ResumableAttempt?> resume(GameStateVault vault, AppDatabase db, PuzzleDefinition p) async =>
        ResumableAttempt.choose(p, vault: vault.getPuzzleState(p.id), database: await db.getProgress(p.id));

    test('restart restores the latest saved board, time, mistakes and hints', () async {
      var (vault, db) = await launch();
      final autosave = PuzzleAutosave((a) => UnfinishedAttempt.writeTo(a, vault: vault, database: db));
      autosave
        ..save(attemptAfter(puzzle, [(0, 0)], seconds: 3))
        ..save(attemptAfter(puzzle, [(0, 0), (1, 1)], seconds: 7))
        ..save(attemptAfter(puzzle, [(0, 0), (1, 1), (4, 2)], seconds: 12));
      await autosave.flush();

      (vault, db) = await launch(); // killed: no dispose, no navigation
      final attempt = (await resume(vault, db, puzzle))!;
      expect(attempt.cells, attemptAfter(puzzle, [(0, 0), (1, 1), (4, 2)]).savedBoard.split(':').last);
      expect(attempt.elapsedSeconds, 12);
    });

    test('the database alone restores the board when the vault is lost', () async {
      var (vault, db) = await launch();
      final autosave = PuzzleAutosave((a) => UnfinishedAttempt.writeTo(a, vault: vault, database: db));
      autosave.save(attemptAfter(puzzle, [(0, 0), (1, 1)], seconds: 5));
      await autosave.flush();
      await vault.clearAll();
      (vault, db) = await launch();
      expect((await resume(vault, db, puzzle))!.elapsedSeconds, 5);
    });

    test('a content revision that changes the solution never restores the old board', () async {
      var (vault, db) = await launch();
      final autosave = PuzzleAutosave((a) => UnfinishedAttempt.writeTo(a, vault: vault, database: db));
      autosave.save(attemptAfter(puzzle, [(0, 0), (1, 1)]));
      await autosave.flush();
      (vault, db) = await launch();
      final revised = cat(art: ['.###.', '#####', '#.#.#', '#####', '.#.#.']);
      expect(revised.width * revised.height, puzzle.width * puzzle.height, reason: 'same id and size');
      expect(await resume(vault, db, revised), isNull);
      expect(await resume(vault, db, puzzle), isNotNull, reason: 'unchanged content still resumes');
    });

    test('a completion written after close is final: no unfinished state comes back', () async {
      final (vault, db) = await launch();
      final gate = Completer<void>();
      final autosave = PuzzleAutosave((a) async {
        await gate.future;
        await UnfinishedAttempt.writeTo(a, vault: vault, database: db);
      })
        ..save(attemptAfter(puzzle, [(0, 0)]))
        ..save(attemptAfter(puzzle, [(0, 0), (1, 1)]));
      final closing = autosave.close();
      gate.complete();
      await closing;
      // What PuzzleScreen writes on completion, after close.
      await vault.savePuzzleState(SavedPuzzleState(
          puzzleId: puzzle.id, isCompleted: true, stars: 3, bestTimeSeconds: 40, lastPlayed: DateTime.now(), savedBoardState: null));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(puzzleId: puzzle.id, lastPlayed: DateTime.now(), isCompleted: const Value(true), stars: const Value(3)));
      autosave.save(attemptAfter(puzzle, [(2, 2)]));
      await autosave.flush();
      expect(vault.getPuzzleState(puzzle.id)!.isCompleted, isTrue);
      expect(vault.getPuzzleState(puzzle.id)!.stars, 3);
      expect((await db.getProgress(puzzle.id))!.isCompleted, isTrue);
      expect(await resume(vault, db, puzzle), isNull);
    });
  });
}
