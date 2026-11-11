// N-2 on the real screens: coins for the first completion only (also for the Daily and for
// puzzles completed by earlier versions), the best result kept, the home pill current.
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
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/features/collections/domain/puzzle_repository.dart';
import 'package:nonogram/features/home/presentation/home_screen.dart';
import 'package:nonogram/features/puzzle_game/presentation/puzzle_screen.dart';
import 'package:nonogram/features/puzzle_game/presentation/widgets/artwork_reveal_widget.dart';
import 'package:nonogram/features/puzzle_game/presentation/widgets/puzzle_board_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';

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

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nonogram_reward_screen_');
    EncryptedStorageBox.resetRegistryForTesting();
    vault = GameStateVault.instance;
    await vault.initialize(storageDirectoryPath: dir.path);
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
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

  Future<void> show(WidgetTester tester, Widget home) async {
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
      child: MaterialApp(home: home),
    ));
    await settle(tester);
  }

  Future<void> fill(WidgetTester tester, int r, int c) async {
    final board = find.descendant(of: find.byType(PuzzleBoardWidget), matching: find.byType(GestureDetector)).first;
    final rect = tester.getRect(board);
    const clueW = 2 * 18.0 + 14;
    const clueH = 2 * 16.0 + 12;
    final cell = (rect.width - clueW) / cat.width;
    final g = await tester.startGesture(rect.topLeft + Offset(clueW + c * cell + 3, clueH + (r + .5) * cell));
    await g.moveBy(const Offset(kTouchSlop + 2, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> solve(WidgetTester tester, {Duration pause = Duration.zero}) async {
    for (var r = 0; r < cat.height; r++) {
      for (var c = 0; c < cat.width; c++) {
        if (cat.encodedSolution[r * cat.width + c] == '1') {
          await fill(tester, r, c);
          if (pause > Duration.zero) await tester.pump(pause);
        }
      }
    }
    await settle(tester);
  }

  /// Lets the completion chain finish (real I/O between fake-clock delays).
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
    }
  }

  Future<int> coins(WidgetTester tester) async => (await tester.runAsync(db.getOrCreateEconomy))!.coins;

  Future<void> replayFromDialog(WidgetTester tester) async {
    tester.widget<ArtworkRevealDialog>(find.byType(ArtworkRevealDialog)).onReplay();
    await tester.pump();
    await settle(tester);
  }

  testWidgets('first completion pays stars × 15; replays in the same screen pay nothing', (tester) async {
    await show(tester, const PuzzleScreen(puzzleId: 'cat_5x5'));
    await solve(tester, pause: const Duration(seconds: 2));
    await drain(tester);
    expect(await coins(tester), 100 + 3 * 15);
    final firstTime = vault.getPuzzleState(cat.id)!.bestTimeSeconds;
    expect(firstTime, greaterThan(0));

    await replayFromDialog(tester);
    await solve(tester, pause: const Duration(seconds: 1)); // faster
    await drain(tester);
    expect(await coins(tester), 145, reason: 'replay: no coins');
    final state = vault.getPuzzleState(cat.id)!;
    expect(state.isCompleted, isTrue);
    expect(state.stars, 3);
    expect(state.bestTimeSeconds, lessThan(firstTime), reason: 'faster replay improves the best time');
    expect((await tester.runAsync(() => db.getProgress(cat.id)))!.bestTimeSeconds, state.bestTimeSeconds);

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('a puzzle completed by an earlier version pays nothing and keeps its best result', (tester) async {
    await tester.runAsync(() async {
      await vault.savePuzzleState(SavedPuzzleState(puzzleId: cat.id, isCompleted: true, stars: 3, bestTimeSeconds: 2, lastPlayed: DateTime(2026, 10, 1)));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
          puzzleId: cat.id, lastPlayed: DateTime(2026, 10, 1), isCompleted: const Value(true), stars: const Value(3), bestTimeSeconds: const Value(2)));
    });
    await show(tester, const PuzzleScreen(puzzleId: 'cat_5x5'));
    await solve(tester, pause: const Duration(seconds: 1));
    await drain(tester);
    expect(await coins(tester), 100);
    expect([vault.getPuzzleState(cat.id)!.stars, vault.getPuzzleState(cat.id)!.bestTimeSeconds], [3, 2]);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('a completed puzzle opens fresh even if an earlier version left an unfinished board', (tester) async {
    await tester.runAsync(() async {
      // Earlier versions replaced the vault record with the replay's unfinished board.
      await vault.savePuzzleState(SavedPuzzleState(
          puzzleId: cat.id, isCompleted: false, stars: 0, bestTimeSeconds: 0, lastPlayed: DateTime(2026, 10, 2),
          savedBoardState: SavedBoard.encode(cat, '1${'0' * 24}'), savedElapsedSeconds: 6));
      await db.saveProgress(PuzzleProgressEntriesCompanion.insert(
          puzzleId: cat.id, lastPlayed: DateTime(2026, 10, 1), isCompleted: const Value(true), stars: const Value(3), bestTimeSeconds: const Value(9)));
    });
    await show(tester, const PuzzleScreen(puzzleId: 'cat_5x5'));
    expect(find.text('00:00'), findsOneWidget, reason: 'fresh replay, not the old unfinished board');
    await solve(tester, pause: const Duration(seconds: 1));
    await drain(tester);
    expect(await coins(tester), 100);
    expect([vault.getPuzzleState(cat.id)!.isCompleted, vault.getPuzzleState(cat.id)!.stars, vault.getPuzzleState(cat.id)!.bestTimeSeconds], [true, 3, 9]);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('Daily: coins once, one record per date, only a faster time replaces it', (tester) async {
    await show(tester, const PuzzleScreen(puzzleId: 'cat_5x5', isDaily: true));
    await solve(tester, pause: const Duration(seconds: 2));
    await drain(tester);
    expect(await coins(tester), 145);
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    final first = (await tester.runAsync(() => db.getDaily(dateKey)))!;
    expect(first.isCompleted, isTrue);

    await replayFromDialog(tester);
    await solve(tester, pause: const Duration(seconds: 4)); // slower
    await drain(tester);
    final slower = (await tester.runAsync(() => db.getDaily(dateKey)))!;
    expect(slower.timeSeconds, first.timeSeconds, reason: 'a slower replay keeps the time');
    expect(slower.completedAt, first.completedAt, reason: 'the first completion stays the record');

    await replayFromDialog(tester);
    await solve(tester, pause: const Duration(seconds: 1)); // faster
    await drain(tester);
    final faster = (await tester.runAsync(() => db.getDaily(dateKey)))!;
    expect(faster.timeSeconds, lessThan(first.timeSeconds));
    expect(await coins(tester), 145, reason: 'Daily replays pay nothing');

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('the home coin pill updates when coins change, without a relaunch', (tester) async {
    await show(tester, const HomeScreen());
    expect(find.text('100'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    await tester.runAsync(() => container.read(economyManagerProvider).grantReward(addCoins: 45));
    await tester.pump();
    expect(find.text('145'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
