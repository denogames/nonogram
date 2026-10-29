import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
import 'core/audio/haptics_service.dart';
import 'core/monetization/economy/economy_manager.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/database/app_database.dart';
import 'core/storage/preferences/app_preferences.dart';
import 'core/storage/vault/game_state_vault.dart';
import 'core/theme/app_theme.dart';
import 'features/collections/domain/puzzle_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Resolve persistent application support directory
  final appSupportDir = await getApplicationSupportDirectory();

  // 2. Initialize Studio Core SDK in offline-first mode (zero network packets)
  final sdk = await StudioSdk.initialize(
    gameId: 'nonogram',
    storageDirectoryPath: appSupportDir.path,
    config: const StudioConfig(
      enableCloudSync: false,
      enableDebugOverlay: false,
      initialCurrencies: {
        StudioCurrencyIds.gold: 100,
        StudioCurrencyIds.hints: 5,
      },
    ),
  );

  // 3. Initialize crash-safe game state vault in app support directory
  await GameStateVault.instance.initialize(
    storageDirectoryPath: appSupportDir.path,
  );

  // 4. Storage & Preferences Initialization
  final database = AppDatabase();
  final preferences = await AppPreferences.load();

  // Set initial haptics state
  HapticsService.enabled = preferences.hapticsEnabled;

  // 5. Load Curated Bundled Puzzle Collections
  final puzzleRepository = PuzzleRepository();
  await puzzleRepository.loadBundledPuzzles();

  // 6. Economy Preload backed by Single-Source Studio Core Wallet
  final economyManager = EconomyManager(db: database, wallet: sdk.wallet);
  await economyManager.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        preferencesProvider.overrideWithValue(preferences),
        puzzleRepositoryProvider.overrideWithValue(puzzleRepository),
        economyManagerProvider.overrideWithValue(economyManager),
      ],
      child: const NonogramApp(),
    ),
  );
}

class NonogramApp extends ConsumerWidget {
  const NonogramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeData = AppTheme.getThemeData(themeMode);

    return MaterialApp.router(
      title: 'Nonogram',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      routerConfig: appRouter,
    );
  }
}
