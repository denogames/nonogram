// N-2: a completion is recorded once as "first" (the one that pays), never reverts, and keeps
// the best stars and the fastest valid time; also across restarts, concurrent calls and data
// written by earlier versions.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/storage/completion_record.dart';
import 'package:nonogram/core/storage/database/app_database.dart';
import 'package:nonogram/core/storage/vault/game_state_vault.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

void main() {
  late Directory dir;
  late File dbFile;
  final open = <AppDatabase>[];
  const id = 'cat_5x5';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nonogram_completion_');
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

  /// One app process: database file and crash-safe vault.
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

  Future<CompletionOutcome> complete(GameStateVault v, AppDatabase db, int stars, int seconds) =>
      CompletionRecords.record(puzzleId: id, stars: stars, timeSeconds: seconds, vault: v, database: db);

  Future<void> expectStored(GameStateVault v, AppDatabase db, int stars, int seconds) async {
    final row = (await db.getProgress(id))!;
    final saved = v.getPuzzleState(id)!;
    expect([row.isCompleted, row.stars, row.bestTimeSeconds], [true, stars, seconds]);
    expect([saved.isCompleted, saved.stars, saved.bestTimeSeconds, saved.savedBoardState], [true, stars, seconds, null]);
  }

  test('first completion is first; worse replays keep the best, better replays improve it', () async {
    final (v, db) = await launch();
    final first = await complete(v, db, 2, 60);
    expect(first.firstCompletion, isTrue);
    await expectStored(v, db, 2, 60);

    final worse = await complete(v, db, 1, 90);
    expect(worse.firstCompletion, isFalse);
    await expectStored(v, db, 2, 60);

    final better = await complete(v, db, 3, 40);
    expect(better.firstCompletion, isFalse);
    expect([better.bestStars, better.bestTimeSeconds], [3, 40]);
    await expectStored(v, db, 3, 40);

    final mixed = await complete(v, db, 1, 25); // faster but fewer stars
    await expectStored(v, db, 3, 25);
    expect(mixed.firstCompletion, isFalse);
  });

  test('a zero time is not a valid best time', () async {
    final (v, db) = await launch();
    await complete(v, db, 3, 0);
    await complete(v, db, 3, 50);
    await expectStored(v, db, 3, 50);
    await complete(v, db, 3, 0);
    await expectStored(v, db, 3, 50);
  });

  test('concurrent and duplicate completions: exactly one is first', () async {
    final (v, db) = await launch();
    final outcomes = await Future.wait([for (var i = 0; i < 5; i++) complete(v, db, 3, 30 + i)]);
    expect(outcomes.where((o) => o.firstCompletion), hasLength(1));
    await expectStored(v, db, 3, 30);
  });

  test('after a restart a replay is not first', () async {
    var (v, db) = await launch();
    expect((await complete(v, db, 3, 45)).firstCompletion, isTrue);
    (v, db) = await launch();
    expect((await complete(v, db, 3, 30)).firstCompletion, isFalse);
    await expectStored(v, db, 3, 30);
  });

  group('data from earlier versions', () {
    test('a completed puzzle (vault and database) is not first', () async {
      final (v, db) = await launch();
      await v.savePuzzleState(SavedPuzzleState(puzzleId: id, isCompleted: true, stars: 3, bestTimeSeconds: 20, lastPlayed: DateTime(2026, 10, 1)));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
          puzzleId: id, lastPlayed: DateTime(2026, 10, 1), isCompleted: const Value(true), stars: const Value(3), bestTimeSeconds: const Value(20)));
      final o = await complete(v, db, 1, 99);
      expect(o.firstCompletion, isFalse);
      await expectStored(v, db, 3, 20);
    });

    test('a completion overwritten by an earlier replay (unfinished save) is still recognised and restored', () async {
      final (v, db) = await launch();
      // What earlier versions left after leaving a replay: vault replaced (stars 0, unfinished),
      // database row marked unfinished but still holding stars and best time.
      await v.savePuzzleState(SavedPuzzleState(
          puzzleId: id, isCompleted: false, stars: 0, bestTimeSeconds: 0, lastPlayed: DateTime(2026, 10, 2), savedBoardState: 'fp1:x:0000'));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
          puzzleId: id, lastPlayed: DateTime(2026, 10, 2), isCompleted: const Value(false), stars: const Value(2), bestTimeSeconds: const Value(70)));
      expect(CompletionRecords.wasCompleted(v.getPuzzleState(id), await db.getProgress(id)), isTrue);
      final o = await complete(v, db, 1, 80);
      expect(o.firstCompletion, isFalse);
      await expectStored(v, db, 2, 70);
    });

    test('only the vault knows (database lost): not first', () async {
      final (v, db) = await launch();
      await v.savePuzzleState(SavedPuzzleState(puzzleId: id, isCompleted: true, stars: 2, bestTimeSeconds: 33, lastPlayed: DateTime(2026, 10, 3)));
      expect((await complete(v, db, 3, 40)).firstCompletion, isFalse);
      await expectStored(v, db, 3, 33);
    });

    test('an unfinished attempt of a never-completed puzzle does not count as completed', () async {
      final (v, db) = await launch();
      await v.savePuzzleState(SavedPuzzleState(
          puzzleId: id, isCompleted: false, stars: 0, bestTimeSeconds: 0, lastPlayed: DateTime(2026, 11, 11), savedBoardState: 'fp1:x:0000'));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(puzzleId: id, lastPlayed: DateTime(2026, 11, 11), savedBoardState: const Value('fp1:x:0000')));
      expect((await complete(v, db, 3, 40)).firstCompletion, isTrue);
    });
  });
}
