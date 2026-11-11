// N-1 on the real PuzzleScreen: moves are saved while the screen stays open, leaving the
// foreground flushes the latest time, completion is final, and the default (remote content
// off) makes no network request.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/providers/app_providers.dart';
import 'package:nonogram/core/storage/database/app_database.dart';
import 'package:nonogram/core/storage/preferences/app_preferences.dart';
import 'package:nonogram/core/storage/saved_board.dart';
import 'package:nonogram/core/storage/vault/game_state_vault.dart';
import 'package:nonogram/engine/game/puzzle_engine.dart';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/engine/models/cell_state.dart';
import 'package:nonogram/features/collections/domain/puzzle_repository.dart';
import 'package:nonogram/features/puzzle_game/presentation/puzzle_screen.dart';
import 'package:nonogram/features/puzzle_game/presentation/widgets/puzzle_board_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

/// Counts every HttpClient the code under test creates.
class _CountingHttp extends HttpOverrides {
  int clients = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clients++;
    return super.createHttpClient(context);
  }
}

final cat = PuzzleGenerator.fromAsciiArt(
  id: 'cat_5x5',
  title: 'Cat',
  category: 'animals',
  asciiLines: ['#...#', '#####', '##.##', '.###.', '..#..'],
);

void main() {
  late Directory dir;
  late AppDatabase db;
  late GameStateVault vault;
  late _CountingHttp http;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nonogram_screen_autosave_');
    EncryptedStorageBox.resetRegistryForTesting();
    vault = GameStateVault.instance;
    await vault.initialize(storageDirectoryPath: dir.path);
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    http = _CountingHttp();
    HttpOverrides.global = http;
  });
  tearDown(() async {
    HttpOverrides.global = null;
    await vault.clearAll();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2160, 4800); // wide enough for the test font
    tester.view.devicePixelRatio = 3.0;
    final prefs = await AppPreferences.load();
    final repo = PuzzleRepository()..registerPuzzles([cat]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesProvider.overrideWithValue(prefs),
        puzzleRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: const MaterialApp(home: PuzzleScreen(puzzleId: 'cat_5x5')),
    ));
    await settle(tester);
  }

  /// Fills cell (r, c) with a short stroke, as a finger does.
  Future<void> fill(WidgetTester tester, int r, int c) async {
    final board = find.descendant(of: find.byType(PuzzleBoardWidget), matching: find.byType(GestureDetector)).first;
    final rect = tester.getRect(board);
    const clueW = 2 * 18.0 + 14; // two row clues at most
    const clueH = 2 * 16.0 + 12; // two column clues at most
    final cell = (rect.width - clueW) / cat.width;
    final start = rect.topLeft + Offset(clueW + c * cell + 3, clueH + (r + .5) * cell);
    final g = await tester.startGesture(start);
    await g.moveBy(const Offset(kTouchSlop + 2, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
  }

  String cellsAfter(List<(int, int)> fills) {
    final e = PuzzleEngine(puzzle: cat);
    for (final (r, c) in fills) {
      e.applyTool(r, c, EditTool.fill);
    }
    return e.serializeBoardState();
  }

  Future<ResumableAttempt?> saved(WidgetTester tester) async => ResumableAttempt.choose(cat,
      vault: vault.getPuzzleState(cat.id), database: await tester.runAsync<PuzzleProgressEntry?>(() => db.getProgress(cat.id)));

  testWidgets('moves are saved without leaving the screen; background flushes the time', (tester) async {
    await open(tester);
    await fill(tester, 0, 0);
    await settle(tester);
    expect((await saved(tester))!.cells, cellsAfter([(0, 0)]), reason: 'one move, screen still open');

    // Rapid moves: the latest board is what is stored.
    for (final c in [0, 1, 2, 3, 4]) {
      await fill(tester, 1, c);
    }
    await settle(tester);
    final moves = [(0, 0), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4)];
    expect((await saved(tester))!.cells, cellsAfter(moves));
    expect(SavedBoard.parse(vault.getPuzzleState(cat.id)!.savedBoardState!).fingerprint, SavedBoard.fingerprintOf(cat));

    // Time passes with no move, then the app leaves the foreground.
    await tester.pump(const Duration(seconds: 4));
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await settle(tester);
    final attempt = (await saved(tester))!;
    expect(attempt.cells, cellsAfter(moves));
    expect(attempt.elapsedSeconds, greaterThanOrEqualTo(4));
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await settle(tester);

    expect(http.clients, 0, reason: 'default build: no network');
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('completion is final: stars and reward kept, no unfinished board comes back', (tester) async {
    await open(tester);
    final solution = [
      for (var r = 0; r < cat.height; r++)
        for (var c = 0; c < cat.width; c++)
          if (cat.encodedSolution[r * cat.width + c] == '1') (r, c),
    ];
    for (final (r, c) in solution) {
      await fill(tester, r, c);
    }
    await settle(tester);

    final state = vault.getPuzzleState(cat.id)!;
    expect(state.isCompleted, isTrue);
    expect(state.stars, 3);
    expect(state.savedBoardState, isNull);
    final row = (await tester.runAsync(() => db.getProgress(cat.id)))!;
    expect(row.isCompleted, isTrue);
    expect((await tester.runAsync(db.getOrCreateEconomy))!.coins, 100 + 3 * 15);

    // Leaving the screen and the app going to the background write nothing unfinished.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Let the completion chain (real I/O between fake-clock delays: ads, haptics, reveal) finish.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    expect(vault.getPuzzleState(cat.id)!.isCompleted, isTrue);
    expect((await tester.runAsync(() => db.getProgress(cat.id)))!.isCompleted, isTrue);
    expect(await saved(tester), isNull);
  });

  testWidgets('a completed puzzle that is replayed keeps its completion', (tester) async {
    await tester.runAsync(() async {
      await vault.savePuzzleState(SavedPuzzleState(
          puzzleId: cat.id, isCompleted: true, stars: 3, bestTimeSeconds: 30, lastPlayed: DateTime(2026, 11, 11), savedBoardState: null));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
          puzzleId: cat.id, lastPlayed: DateTime(2026, 11, 11), isCompleted: const Value(true), stars: const Value(3)));
    });
    await open(tester);
    await fill(tester, 0, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    expect(vault.getPuzzleState(cat.id)!.isCompleted, isTrue);
    expect(vault.getPuzzleState(cat.id)!.stars, 3);
    expect((await tester.runAsync(() => db.getProgress(cat.id)))!.isCompleted, isTrue);
  });
}
