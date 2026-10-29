import 'dart:developer' as dev;
import 'ad_provider.dart';

/// Clean placeholder hook for future Google AdMob integration.
/// In this v1 offline release, AdMob remains unconfigured and inactive (zero network packets).
class AdMobAdProvider implements AdProvider {
  final bool isConfigured;

  const AdMobAdProvider({this.isConfigured = false});

  @override
  Future<void> initialize() async {
    if (!isConfigured) {
      dev.log(
        '[AdMobAdProvider] Offline v1: AdMob unconfigured; skipping network initialization.',
        name: 'AdMob',
      );
      return;
    }
    // Future production AdMob SDK initialization hook:
    // await MobileAds.instance.initialize();
  }

  @override
  bool isInterstitialReady(AdPlacement placement) => isConfigured;

  @override
  bool isRewardedAdReady(AdPlacement placement) => isConfigured;

  @override
  Future<bool> showInterstitial(AdPlacement placement) async {
    if (!isConfigured) return false;
    return true;
  }

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    if (!isConfigured) return false;
    return false;
  }
}
