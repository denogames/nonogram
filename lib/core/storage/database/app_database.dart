import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Table storing player progress per puzzle.
class PuzzleProgressEntries extends Table {
  TextColumn get puzzleId => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  IntColumn get bestTimeSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayed => dateTime()();
  TextColumn get savedBoardState => text().nullable()();
  IntColumn get savedMistakes => integer().withDefault(const Constant(0))();
  IntColumn get savedHintsUsed => integer().withDefault(const Constant(0))();
  IntColumn get savedElapsedSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {puzzleId};
}

/// Table storing daily puzzle completion history.
class DailyPuzzleEntries extends Table {
  TextColumn get dateKey => text()(); // Format: YYYY-MM-DD
  TextColumn get puzzleId => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get timeSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {dateKey};
}

/// Table storing offline player economy (hints, coins, streak).
class PlayerEconomyEntries extends Table {
  TextColumn get id => text()();
  IntColumn get coins => integer().withDefault(const Constant(50))();
  IntColumn get hintsRemaining => integer().withDefault(const Constant(5))();
  TextColumn get lastDailyRewardDate => text().nullable()();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table storing verified purchase entitlements (e.g. ads_free).
class EntitlementEntries extends Table {
  TextColumn get entitlementId => text()(); // e.g. 'ads_free'
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get source => text()(); // 'google_play', 'apple_app_store', 'mock'
  DateTimeColumn get acquiredAt => dateTime()();
  TextColumn get signature => text().nullable()();

  @override
  Set<Column> get primaryKey => {entitlementId};
}

@DriftDatabase(tables: [
  PuzzleProgressEntries,
  DailyPuzzleEntries,
  PlayerEconomyEntries,
  EntitlementEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'nonogram_game_db');
  }

  // Helper CRUD methods

  // --- Puzzle Progress ---
  Future<PuzzleProgressEntry?> getProgress(String puzzleId) =>
      (select(puzzleProgressEntries)..where((tbl) => tbl.puzzleId.equals(puzzleId)))
          .getSingleOrNull();

  Stream<List<PuzzleProgressEntry>> watchAllProgress() =>
      select(puzzleProgressEntries).watch();

  Future<void> saveProgress(PuzzleProgressEntriesCompanion entry) =>
      into(puzzleProgressEntries).insertOnConflictUpdate(entry);

  // --- Daily Puzzles ---
  Future<DailyPuzzleEntry?> getDaily(String dateKey) =>
      (select(dailyPuzzleEntries)..where((tbl) => tbl.dateKey.equals(dateKey)))
          .getSingleOrNull();

  Stream<List<DailyPuzzleEntry>> watchDailyHistory() =>
      (select(dailyPuzzleEntries)..orderBy([(tbl) => OrderingTerm.desc(tbl.dateKey)]))
          .watch();

  Future<void> saveDaily(DailyPuzzleEntriesCompanion entry) =>
      into(dailyPuzzleEntries).insertOnConflictUpdate(entry);

  // --- Economy ---
  Future<PlayerEconomyEntry> getOrCreateEconomy() async {
    const defaultId = 'player_main';
    final existing = await (select(playerEconomyEntries)
          ..where((tbl) => tbl.id.equals(defaultId)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final initial = PlayerEconomyEntriesCompanion.insert(
      id: defaultId,
      coins: const Value(100),
      hintsRemaining: const Value(5),
      streakDays: const Value(0),
    );
    await into(playerEconomyEntries).insert(initial);
    return (await (select(playerEconomyEntries)
          ..where((tbl) => tbl.id.equals(defaultId)))
        .getSingle());
  }

  Future<void> updateEconomy(PlayerEconomyEntriesCompanion entry) =>
      into(playerEconomyEntries).insertOnConflictUpdate(entry);

  // --- Entitlements ---
  Future<bool> hasActiveEntitlement(String entitlementId) async {
    final entry = await (select(entitlementEntries)
          ..where((tbl) =>
              tbl.entitlementId.equals(entitlementId) & tbl.isActive.equals(true)))
        .getSingleOrNull();
    return entry != null;
  }

  Future<void> setEntitlement({
    required String entitlementId,
    required bool isActive,
    required String source,
    String? signature,
  }) async {
    await into(entitlementEntries).insertOnConflictUpdate(
      EntitlementEntriesCompanion.insert(
        entitlementId: entitlementId,
        isActive: Value(isActive),
        source: source,
        acquiredAt: DateTime.now(),
        signature: Value(signature),
      ),
    );
  }
}
