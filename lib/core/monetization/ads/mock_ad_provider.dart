import 'dart:async';
import 'dart:developer' as dev;
import 'ad_provider.dart';

/// Mock Ad Provider for testing, offline use, and development environments.
class MockAdProvider implements AdProvider {
  bool simulateAdFailure = false;
  int interstitialShownCount = 0;
  int rewardedShownCount = 0;

  @override
  Future<void> initialize() async {
    dev.log('MockAdProvider initialized', name: 'MockAdProvider');
  }

  @override
  bool isInterstitialReady(AdPlacement placement) => !simulateAdFailure;

  @override
  bool isRewardedAdReady(AdPlacement placement) => !simulateAdFailure;

  @override
  Future<bool> showInterstitial(AdPlacement placement) async {
    if (simulateAdFailure) return false;
    interstitialShownCount++;
    dev.log('📺 [MockAdProvider] Displayed Interstitial at $placement', name: 'MockAdProvider');
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    if (simulateAdFailure) return false;
    rewardedShownCount++;
    dev.log('🎁 [MockAdProvider] Displayed Rewarded Ad at $placement (Reward Granted)', name: 'MockAdProvider');
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }
}
