import 'package:drift/drift.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
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
  final CurrencyWalletNotifier? wallet;
  PlayerEconomyEntry? _cachedEconomy;

  EconomyManager({required this.db, this.wallet});

  int get coins {
    if (wallet != null) {
      return wallet!.getBalance(StudioCurrencyIds.gold);
    }
    return _cachedEconomy?.coins ?? 100;
  }

  int get hintsRemaining {
    if (wallet != null) {
      return wallet!.getBalance(StudioCurrencyIds.hints);
    }
    return _cachedEconomy?.hintsRemaining ?? 5;
  }

  int get streakDays => _cachedEconomy?.streakDays ?? 0;
  String? get lastRewardDate => _cachedEconomy?.lastDailyRewardDate;

  Future<void> initialize() async {
    _cachedEconomy = await db.getOrCreateEconomy();

    if (wallet != null) {
      final dbCoins = _cachedEconomy?.coins ?? 100;
      final dbHints = _cachedEconomy?.hintsRemaining ?? 5;

      final wGold = wallet!.getBalance(StudioCurrencyIds.gold);
      final wHints = wallet!.getBalance(StudioCurrencyIds.hints);

      if (wGold > 0 || wHints > 0) {
        await db.updateEconomy(
          PlayerEconomyEntriesCompanion(
            id: const Value('player_main'),
            coins: Value(wGold),
            hintsRemaining: Value(wHints),
          ),
        );
        _cachedEconomy = await db.getOrCreateEconomy();
      } else {
        await wallet!.credit(StudioCurrencyIds.gold, dbCoins, source: 'init_sync');
        await wallet!.credit(StudioCurrencyIds.hints, dbHints, source: 'init_sync');
      }

      wallet!.watchCurrency(StudioCurrencyIds.gold).addListener(_syncDbFromWallet);
      wallet!.watchCurrency(StudioCurrencyIds.hints).addListener(_syncDbFromWallet);
    }
  }

  void dispose() {
    wallet?.watchCurrency(StudioCurrencyIds.gold).removeListener(_syncDbFromWallet);
    wallet?.watchCurrency(StudioCurrencyIds.hints).removeListener(_syncDbFromWallet);
  }

  void _syncDbFromWallet() {
    if (wallet == null) return;
    try {
      final wCoins = wallet!.getBalance(StudioCurrencyIds.gold);
      final wHints = wallet!.getBalance(StudioCurrencyIds.hints);
      db.updateEconomy(
        PlayerEconomyEntriesCompanion(
          id: const Value('player_main'),
          coins: Value(wCoins),
          hintsRemaining: Value(wHints),
        ),
      );
    } catch (_) {
      // Ignore if db is closed in headless tests
    }
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
    // LiveOps balance override or fallback
    int baseCoins = StudioSdk.isInitialized
        ? StudioSdk.instance.liveOps.getBalanceValue<int>('daily_reward_base_coins', defaultValue: 50)
        : 50;
    int bonusCoins = baseCoins + (newStreak.clamp(1, 7) * 10);
    int bonusHints = (newStreak % 3 == 0) ? 2 : 1;

    if (wallet != null) {
      await wallet!.credit(StudioCurrencyIds.gold, bonusCoins, source: 'daily_reward');
      await wallet!.credit(StudioCurrencyIds.hints, bonusHints, source: 'daily_reward');
    }

    final updatedCoins = coins + (wallet == null ? bonusCoins : 0);
    final updatedHints = hintsRemaining + (wallet == null ? bonusHints : 0);

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
    if (wallet != null) {
      final success = await wallet!.trySpend(
        StudioCurrencyIds.hints,
        1,
        reason: 'nonogram_hint_used',
      );
      if (!success) return false;

      await db.updateEconomy(
        PlayerEconomyEntriesCompanion(
          id: const Value('player_main'),
          hintsRemaining: Value(wallet!.getBalance(StudioCurrencyIds.hints)),
        ),
      );
      _cachedEconomy = await db.getOrCreateEconomy();
      return true;
    }

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

  /// Buys 1 hint for coins (supports remote game_balance override).
  Future<bool> buyHintWithCoins({int cost = 50, int hintsToAdd = 1}) async {
    final effectiveCost = StudioSdk.isInitialized
        ? StudioSdk.instance.liveOps.getBalanceValue<int>('hint_cost_coins', defaultValue: cost)
        : cost;

    if (wallet != null) {
      final spent = await wallet!.trySpend(
        StudioCurrencyIds.gold,
        effectiveCost,
        reason: 'buy_hint_with_coins',
      );
      if (!spent) return false;

      await wallet!.credit(
        StudioCurrencyIds.hints,
        hintsToAdd,
        source: 'buy_hint_granted',
      );

      await db.updateEconomy(
        PlayerEconomyEntriesCompanion(
          id: const Value('player_main'),
          coins: Value(wallet!.getBalance(StudioCurrencyIds.gold)),
          hintsRemaining: Value(wallet!.getBalance(StudioCurrencyIds.hints)),
        ),
      );
      _cachedEconomy = await db.getOrCreateEconomy();
      return true;
    }

    if (coins < effectiveCost) return false;

    await db.updateEconomy(
      PlayerEconomyEntriesCompanion(
        id: const Value('player_main'),
        coins: Value(coins - effectiveCost),
        hintsRemaining: Value(hintsRemaining + hintsToAdd),
      ),
    );

    _cachedEconomy = await db.getOrCreateEconomy();
    return true;
  }

  /// Grants free reward (e.g. from rewarded ad or inbox gift).
  Future<void> grantReward({int addCoins = 0, int addHints = 0}) async {
    if (wallet != null) {
      if (addCoins > 0) {
        await wallet!.credit(StudioCurrencyIds.gold, addCoins, source: 'grant_reward');
      }
      if (addHints > 0) {
        await wallet!.credit(StudioCurrencyIds.hints, addHints, source: 'grant_reward');
      }
    }

    final newCoins = coins + (wallet == null ? addCoins : 0);
    final newHints = hintsRemaining + (wallet == null ? addHints : 0);

    await db.updateEconomy(
      PlayerEconomyEntriesCompanion(
        id: const Value('player_main'),
        coins: Value(newCoins),
        hintsRemaining: Value(newHints),
      ),
    );

    _cachedEconomy = await db.getOrCreateEconomy();
  }
}
