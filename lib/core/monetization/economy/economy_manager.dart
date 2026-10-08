import 'package:drift/drift.dart';
import '../../storage/database/app_database.dart';

class DailyRewardResult {
  final bool claimed;
  final int coinsGranted;
  final int hintsGranted;
  final int newStreak;

  const DailyRewardResult({
    required this.claimed,
    required this.coinsGranted,
    required this.hintsGranted,
    required this.newStreak,
  });
}

class EconomyManager {
  final AppDatabase db;
  PlayerEconomyEntry? _cachedEconomy;

  EconomyManager({required this.db});

  int get coins => _cachedEconomy?.coins ?? 100;
  int get hintsRemaining => _cachedEconomy?.hintsRemaining ?? 5;
  int get streakDays => _cachedEconomy?.streakDays ?? 0;
  String? get lastRewardDate => _cachedEconomy?.lastDailyRewardDate;

  Future<void> initialize() async {
    _cachedEconomy = await db.getOrCreateEconomy();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool isDailyRewardAvailable() {
    final today = _todayKey();
    return lastRewardDate != today;
  }

  /// Claim daily reward if not already claimed today.
  Future<DailyRewardResult> claimDailyReward() async {
    final today = _todayKey();
    if (!isDailyRewardAvailable()) {
      return DailyRewardResult(
        claimed: false,
        coinsGranted: 0,
        hintsGranted: 0,
        newStreak: streakDays,
      );
    }

    int newStreak = streakDays + 1;
    // Streak reward bonus
    int bonusCoins = 50 + (newStreak.clamp(1, 7) * 10);
    int bonusHints = (newStreak % 3 == 0) ? 2 : 1;

    final updatedCoins = coins + bonusCoins;
    final updatedHints = hintsRemaining + bonusHints;

    await db.updateEconomy(
      PlayerEconomyEntriesCompanion(
        id: const Value('player_main'),
        coins: Value(updatedCoins),
        hintsRemaining: Value(updatedHints),
        lastDailyRewardDate: Value(today),
        streakDays: Value(newStreak),
      ),
    );

    _cachedEconomy = await db.getOrCreateEconomy();

    return DailyRewardResult(
      claimed: true,
      coinsGranted: bonusCoins,
      hintsGranted: bonusHints,
      newStreak: newStreak,
    );
  }

  /// Consumes 1 hint if available. Returns true if successful.
  Future<bool> consumeHint() async {
    if (hintsRemaining <= 0) return false;

    final newCount = hintsRemaining - 1;
    await db.updateEconomy(
      PlayerEconomyEntriesCompanion(
        id: const Value('player_main'),
        hintsRemaining: Value(newCount),
      ),
    );

    _cachedEconomy = await db.getOrCreateEconomy();
    return true;
  }

  /// Buys 1 hint for 50 coins.
  Future<bool> buyHintWithCoins({int cost = 50, int hintsToAdd = 1}) async {
    if (coins < cost) return false;

    await db.updateEconomy(
      PlayerEconomyEntriesCompanion(
        id: const Value('player_main'),
        coins: Value(coins - cost),
        hintsRemaining: Value(hintsRemaining + hintsToAdd),
      ),
    );

    _cachedEconomy = await db.getOrCreateEconomy();
    return true;
  }

  /// Grants free reward (e.g. from rewarded ad).
  Future<void> grantReward({int addCoins = 0, int addHints = 0}) async {
    await db.updateEconomy(
      PlayerEconomyEntriesCompanion(
        id: const Value('player_main'),
        coins: Value(coins + addCoins),
        hintsRemaining: Value(hintsRemaining + addHints),
      ),
    );

    _cachedEconomy = await db.getOrCreateEconomy();
  }
}
