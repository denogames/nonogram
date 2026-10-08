import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/audio/haptics_service.dart';
import 'core/monetization/economy/economy_manager.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/database/app_database.dart';
import 'core/storage/preferences/app_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/collections/domain/puzzle_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Storage & Preferences Initialization
  final database = AppDatabase();
  final preferences = await AppPreferences.load();

  // Set initial haptics state
  HapticsService.enabled = preferences.hapticsEnabled;

  // 2. Load Curated Puzzle Collections
  final puzzleRepository = PuzzleRepository();
  await puzzleRepository.loadBundledPuzzles();

  // 3. Economy Preload
  final economyManager = EconomyManager(db: database);
  await economyManager.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        preferencesProvider.overrideWithValue(preferences),
        puzzleRepositoryProvider.overrideWithValue(puzzleRepository),
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
