import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/storage/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase Drift tests', () {
    test('Saves and reads puzzle progress', () async {
      final now = DateTime.now();
      await database.saveProgress(
        PuzzleProgressEntriesCompanion.insert(
          puzzleId: 'puzzle_test_1',
          isCompleted: const Value(true),
          stars: const Value(3),
          bestTimeSeconds: const Value(45),
          lastPlayed: now,
          savedBoardState: const Value('100010101011111'),
          savedMistakes: const Value(0),
          savedElapsedSeconds: const Value(45),
        ),
      );

      final entry = await database.getProgress('puzzle_test_1');
      expect(entry, isNotNull);
      expect(entry!.isCompleted, isTrue);
      expect(entry.stars, 3);
      expect(entry.bestTimeSeconds, 45);
      expect(entry.savedBoardState, '100010101011111');
    });

    test('Daily puzzle tracking works', () async {
      final today = '2026-10-09';
      await database.saveDaily(
        DailyPuzzleEntriesCompanion.insert(
          dateKey: today,
          puzzleId: 'daily_oct_09',
          isCompleted: const Value(true),
          timeSeconds: const Value(75),
          completedAt: Value(DateTime.now()),
        ),
      );

      final daily = await database.getDaily(today);
      expect(daily, isNotNull);
      expect(daily!.puzzleId, 'daily_oct_09');
      expect(daily.isCompleted, isTrue);
      expect(daily.timeSeconds, 75);
    });

    test('Player economy defaults and updates', () async {
      final economy = await database.getOrCreateEconomy();
      expect(economy.coins, 100);
      expect(economy.hintsRemaining, 5);

      // Spend 1 hint and earn 20 coins
      await database.updateEconomy(
        PlayerEconomyEntriesCompanion(
          id: const Value('player_main'),
          coins: Value(economy.coins + 20),
          hintsRemaining: Value(economy.hintsRemaining - 1),
        ),
      );

      final updated = await database.getOrCreateEconomy();
      expect(updated.coins, 120);
      expect(updated.hintsRemaining, 4);
    });

    test('Entitlements store and check ads_free', () async {
      expect(await database.hasActiveEntitlement('ads_free'), isFalse);

      await database.setEntitlement(
        entitlementId: 'ads_free',
        isActive: true,
        source: 'google_play',
      );

      expect(await database.hasActiveEntitlement('ads_free'), isTrue);

      // Deactivate (e.g. refund/revocation)
      await database.setEntitlement(
        entitlementId: 'ads_free',
        isActive: false,
        source: 'google_play',
      );

      expect(await database.hasActiveEntitlement('ads_free'), isFalse);
    });
  });
}
