import '../../analytics/analytics_service.dart';
import 'ad_provider.dart';
import 'mock_ad_provider.dart';

class AdManager {
  final AdProvider _provider;
  final AnalyticsService _analytics;
  final bool Function() isAdsFreeChecker;

  // Frequency caps
  int _puzzlesCompletedSinceLastAd = 0;
  DateTime? _lastInterstitialTime;
  final int minPuzzlesBetweenAds;
  final Duration minDurationBetweenAds;

  bool adsEnabled = true;

  AdManager({
    AdProvider? provider,
    AnalyticsService? analytics,
    required this.isAdsFreeChecker,
    this.minPuzzlesBetweenAds = 2,
    this.minDurationBetweenAds = const Duration(seconds: 90),
  })  : _provider = provider ?? MockAdProvider(),
        _analytics = analytics ?? AnalyticsService.instance;

  Future<void> initialize() => _provider.initialize();

  bool get isAdsFree => isAdsFreeChecker();

  /// Called upon natural puzzle completion. Evaluates frequency cap and ads-free status.
  Future<bool> maybeShowCompletionInterstitial() async {
    if (!adsEnabled || isAdsFree) return false;

    _puzzlesCompletedSinceLastAd++;
    if (_puzzlesCompletedSinceLastAd < minPuzzlesBetweenAds) return false;

    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed < minDurationBetweenAds) return false;
    }

    if (_provider.isInterstitialReady(AdPlacement.interstitialCompletion)) {
      final shown = await _provider.showInterstitial(AdPlacement.interstitialCompletion);
      if (shown) {
        _puzzlesCompletedSinceLastAd = 0;
        _lastInterstitialTime = DateTime.now();
        await _analytics.logAdImpression(placement: 'interstitial_completion');
        return true;
      }
    }
    return false;
  }

  /// Displays a rewarded ad for obtaining extra hints.
  Future<bool> showRewardedForHint() async {
    if (_provider.isRewardedAdReady(AdPlacement.rewardedHint)) {
      final rewarded = await _provider.showRewarded(AdPlacement.rewardedHint);
      if (rewarded) {
        await _analytics.logRewardedAdCompleted(reward: 'free_hint');
        return true;
      }
    }
    return false;
  }

  /// Displays a rewarded ad for obtaining bonus coins.
  Future<bool> showRewardedForCoins() async {
    if (_provider.isRewardedAdReady(AdPlacement.rewardedCoins)) {
      final rewarded = await _provider.showRewarded(AdPlacement.rewardedCoins);
      if (rewarded) {
        await _analytics.logRewardedAdCompleted(reward: 'coins_50');
        return true;
      }
    }
    return false;
  }
}
