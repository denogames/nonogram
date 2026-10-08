import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engine/models/puzzle_definition.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  String _formatSeconds(int sec) {
    if (sec <= 0) return '--:--';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);
    final db = ref.watch(databaseProvider);
    final repo = ref.watch(puzzleRepositoryProvider);
    final economy = ref.watch(economyManagerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Player Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<PuzzleProgressEntry>>(
        stream: db.watchAllProgress(),
        builder: (context, snapshot) {
          final progressList = snapshot.data ?? [];
          final completed = progressList.where((p) => p.isCompleted).toList();

          int totalStars = completed.fold(0, (sum, p) => sum + p.stars);
          int totalTimeSeconds = completed.fold(0, (sum, p) => sum + p.bestTimeSeconds);

          // Breakdown by difficulty
          final allPuzzles = repo.allPuzzles;
          final puzzleMap = {for (final p in allPuzzles) p.id: p};

          int easyDone = 0, mediumDone = 0, hardDone = 0;
          int easyBest = 999999, mediumBest = 999999, hardBest = 999999;

          for (final c in completed) {
            final def = puzzleMap[c.puzzleId];
            if (def == null) continue;
            switch (def.difficulty) {
              case PuzzleDifficulty.easy:
                easyDone++;
                if (c.bestTimeSeconds > 0 && c.bestTimeSeconds < easyBest) {
                  easyBest = c.bestTimeSeconds;
                }
                break;
              case PuzzleDifficulty.medium:
                mediumDone++;
                if (c.bestTimeSeconds > 0 && c.bestTimeSeconds < mediumBest) {
                  mediumBest = c.bestTimeSeconds;
                }
                break;
              case PuzzleDifficulty.hard:
              case PuzzleDifficulty.expert:
                hardDone++;
                if (c.bestTimeSeconds > 0 && c.bestTimeSeconds < hardBest) {
                  hardBest = c.bestTimeSeconds;
                }
                break;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Top Highlights Cards
              Row(
                children: [
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: Colors.green,
                      title: 'Puzzles Solved',
                      value: '${completed.length}',
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      title: 'Stars Earned',
                      value: '$totalStars',
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.deepOrange,
                      title: 'Daily Streak',
                      value: '${economy.streakDays} Days',
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.timer_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Play Time',
                      value: '${totalTimeSeconds ~/ 60}m',
                      colors: colors,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'DIFFICULTY BREAKDOWN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 10),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DifficultyRow(
                        label: 'Easy (5×5)',
                        solvedCount: easyDone,
                        bestTime: easyBest == 999999 ? '--:--' : _formatSeconds(easyBest),
                        badgeColor: Colors.green,
                        colors: colors,
                      ),
                      const Divider(height: 24),
                      _DifficultyRow(
                        label: 'Medium (10×10)',
                        solvedCount: mediumDone,
                        bestTime: mediumBest == 999999 ? '--:--' : _formatSeconds(mediumBest),
                        badgeColor: Colors.blue,
                        colors: colors,
                      ),
                      const Divider(height: 24),
                      _DifficultyRow(
                        label: 'Hard (15×15)',
                        solvedCount: hardDone,
                        bestTime: hardBest == 999999 ? '--:--' : _formatSeconds(hardBest),
                        badgeColor: Colors.orange,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final PuzzleColors colors;

  const _HighlightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  final String label;
  final int solvedCount;
  final String bestTime;
  final Color badgeColor;
  final PuzzleColors colors;

  const _DifficultyRow({
    required this.label,
    required this.solvedCount,
    required this.bestTime,
    required this.badgeColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '$solvedCount Solved',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(width: 16),
            Text(
              'Best: $bestTime',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
