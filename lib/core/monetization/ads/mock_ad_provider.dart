import 'dart:async';
import 'dart:developer' as dev;
import 'ad_provider.dart';

/// Mock Ad Provider for testing and development environments.
/// In offline mode, simulated reward auto-grants are disabled by default.
class MockAdProvider implements AdProvider {
  bool simulateAdFailure = false;
  bool enableMockRewards = false;
  int interstitialShownCount = 0;
  int rewardedShownCount = 0;

  @override
  Future<void> initialize() async {
    dev.log('MockAdProvider initialized (enableMockRewards: $enableMockRewards)', name: 'MockAdProvider');
  }

  @override
  bool isInterstitialReady(AdPlacement placement) => !simulateAdFailure;

  @override
  bool isRewardedAdReady(AdPlacement placement) => !simulateAdFailure && enableMockRewards;

  @override
  Future<bool> showInterstitial(AdPlacement placement) async {
    if (simulateAdFailure) return false;
    interstitialShownCount++;
    dev.log('📺 [MockAdProvider] Displayed Interstitial at $placement', name: 'MockAdProvider');
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    if (simulateAdFailure || !enableMockRewards) return false;
    rewardedShownCount++;
    dev.log('🎁 [MockAdProvider] Displayed Rewarded Ad at $placement (Reward Granted)', name: 'MockAdProvider');
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
}
