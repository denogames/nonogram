import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/haptics_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engine/models/puzzle_definition.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CollectionDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);
    final repo = ref.watch(puzzleRepositoryProvider);
    final db = ref.watch(databaseProvider);

    final puzzles = repo.getPuzzlesForCategory(categoryId);
    final title = categoryId.substring(0, 1).toUpperCase() + categoryId.substring(1);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<PuzzleProgressEntry>>(
        stream: db.watchAllProgress(),
        builder: (context, snapshot) {
          final progressList = snapshot.data ?? [];
          final progressMap = {for (final p in progressList) p.puzzleId: p};

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: puzzles.length,
            itemBuilder: (context, index) {
              final puzzle = puzzles[index];
              final progress = progressMap[puzzle.id];
              final isDone = progress?.isCompleted ?? false;
              final stars = progress?.stars ?? 0;

              return Card(
                elevation: 3,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  onTap: () {
                    HapticsService.selectionClick();
                    context.push('/puzzle/${puzzle.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: dimensions & difficulty
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.clueBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${puzzle.width}×${puzzle.height}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(puzzle.difficulty).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                puzzle.difficulty.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getDifficultyColor(puzzle.difficulty),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Center: Pixel Art Silhouette / Completion Preview
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? colors.primary.withOpacity(0.1)
                                  : colors.clueBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isDone
                                ? CustomPaint(
                                    painter: _MiniSilhouettePainter(
                                      grid: puzzle.solutionGrid,
                                      width: puzzle.width,
                                      height: puzzle.height,
                                      color: colors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.grid_on_rounded,
                                    size: 32,
                                    color: colors.textSecondary.withOpacity(0.4),
                                  ),
                          ),
                        ),

                        // Bottom: Title & Stars
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDone ? puzzle.title : 'Level ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(3, (i) {
                                final hasStar = i < stars;
                                return Icon(
                                  hasStar ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: hasStar ? Colors.amber : Colors.grey.withOpacity(0.4),
                                  size: 16,
                                );
                              }),
                            ),
                          ],
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

  Color _getDifficultyColor(PuzzleDifficulty diff) {
    switch (diff) {
      case PuzzleDifficulty.easy:
        return Colors.green;
      case PuzzleDifficulty.medium:
        return Colors.blue;
      case PuzzleDifficulty.hard:
        return Colors.orange;
      case PuzzleDifficulty.expert:
        return Colors.red;
    }
  }
}

class _MiniSilhouettePainter extends CustomPainter {
  final List<List<bool>> grid;
  final int width;
  final int height;
  final Color color;

  _MiniSilhouettePainter({
    required this.grid,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / width;
    final cellH = size.height / height;
    final paint = Paint()..color = color;

    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (grid[r][c]) {
          canvas.drawRect(Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSilhouettePainter oldDelegate) => false;
}
