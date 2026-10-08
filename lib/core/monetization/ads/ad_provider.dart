enum AdPlacement {
  interstitialCompletion,
  rewardedHint,
  rewardedCoins,
}

abstract class AdProvider {
  Future<void> initialize();

  /// Whether rewarded ad is currently loaded and ready to display.
  bool isRewardedAdReady(AdPlacement placement);

  /// Whether interstitial ad is currently loaded and ready.
  bool isInterstitialReady(AdPlacement placement);

  /// Shows an interstitial ad.
  Future<bool> showInterstitial(AdPlacement placement);

  /// Shows a rewarded ad. Returns true if user earned the reward.
  Future<bool> showRewarded(AdPlacement placement);
}
