import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/haptics_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/theme/app_theme.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);
    final repo = ref.watch(puzzleRepositoryProvider);
    final db = ref.watch(databaseProvider);

    final categories = repo.getCategories();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Collections', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<PuzzleProgressEntry>>(
        stream: db.watchAllProgress(),
        builder: (context, snapshot) {
          final progressList = snapshot.data ?? [];
          final progressMap = {for (final p in progressList) p.puzzleId: p};

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              int completedCount = 0;
              int totalStars = 0;

              for (final p in cat.puzzles) {
                final entry = progressMap[p.id];
                if (entry != null && entry.isCompleted) {
                  completedCount++;
                  totalStars += entry.stars;
                }
              }

              final progressRatio = cat.puzzles.isEmpty ? 0.0 : completedCount / cat.puzzles.length;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticsService.selectionClick();
                    context.push('/collections/${cat.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _getCategoryIcon(cat.iconName),
                                color: colors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedCount / ${cat.puzzles.length} Completed',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalStars',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            backgroundColor: colors.clueBackground,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'pets':
        return Icons.pets_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }
}
