import 'package:go_router/go_router.dart';
import '../../features/collections/presentation/collection_detail_screen.dart';
import '../../features/collections/presentation/collections_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/puzzle_game/presentation/puzzle_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/tutorial/presentation/tutorial_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/collections',
      builder: (context, state) => const CollectionsScreen(),
      routes: [
        GoRoute(
          path: ':categoryId',
          builder: (context, state) {
            final categoryId = state.pathParameters['categoryId'] ?? 'animals';
            return CollectionDetailScreen(categoryId: categoryId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/puzzle/:puzzleId',
      builder: (context, state) {
        final puzzleId = state.pathParameters['puzzleId'] ?? 'cat_5x5';
        final isDaily = state.uri.queryParameters['daily'] == 'true';
        return PuzzleScreen(puzzleId: puzzleId, isDaily: isDaily);
      },
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
  ],
);
