import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/collections/domain/puzzle_repository.dart';
import '../analytics/analytics_service.dart';
import '../monetization/ads/ad_manager.dart';
import '../monetization/economy/economy_manager.dart';
import '../monetization/iap/iap_manager.dart';
import '../storage/database/app_database.dart';
import '../storage/preferences/app_preferences.dart';
import '../theme/app_theme.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be initialized in main');
});

// Preferences Provider
final preferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError('preferencesProvider must be initialized in main');
});

// Analytics Provider
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

// Puzzle Repository Provider
final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepository();
});

// IAP Manager Provider
final iapManagerProvider = Provider<IapManager>((ref) {
  final db = ref.watch(databaseProvider);
  final analytics = ref.watch(analyticsProvider);
  return IapManager(db: db, analytics: analytics, isMockMode: true);
});

// Ad Manager Provider
final adManagerProvider = Provider<AdManager>((ref) {
  final iap = ref.watch(iapManagerProvider);
  final analytics = ref.watch(analyticsProvider);
  return AdManager(
    analytics: analytics,
    isAdsFreeChecker: () => iap.isAdsFree,
  );
});

// Economy Manager Provider
final economyManagerProvider = Provider<EconomyManager>((ref) {
  final db = ref.watch(databaseProvider);
  return EconomyManager(db: db);
});

// Theme Mode Notifier (Riverpod 3)
class ThemeModeNotifier extends Notifier<NonogramThemeMode> {
  @override
  NonogramThemeMode build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs.themeMode;
  }

  void setTheme(NonogramThemeMode mode) {
    state = mode;
    ref.read(preferencesProvider).setThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, NonogramThemeMode>(ThemeModeNotifier.new);
