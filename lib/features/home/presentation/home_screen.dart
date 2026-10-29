import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/haptics_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);
    final economy = ref.watch(economyManagerProvider);
    final repo = ref.watch(puzzleRepositoryProvider);

    final today = DateTime.now();
    final dailyPuzzle = repo.getDailyPuzzleForDate(today);

    final isRewardReady = economy.isDailyRewardAvailable();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_on_rounded, color: colors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'NONOGRAM',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Coins & Hints Pill
          Center(
            child: InkWell(
              onTap: () => context.push('/shop'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colors.clueBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.gridBorder.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${economy.coins}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.lightbulb_rounded, color: colors.accent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${economy.hintsRemaining}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Reward Claim Banner
            if (isRewardReady)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.accent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Reward Ready!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Claim your free coins & hints for today',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () async {
                        HapticsService.successCelebration();
                        final res = await economy.claimDailyReward();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Claimed +${res.coinsGranted} Coins and +${res.hintsGranted} Hints! (Streak: ${res.newStreak} days)',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Claim'),
                    ),
                  ],
                ),
              ),

            // Daily Nonogram Card
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  HapticsService.selectionClick();
                  if (dailyPuzzle != null) {
                    context.push('/puzzle/${dailyPuzzle.id}?daily=true');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.calendar_today_rounded, color: colors.primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY PUZZLE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dailyPuzzle?.title ?? "Today's Challenge",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Streak: ${economy.streakDays} days',
                              style: TextStyle(fontSize: 13, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Collections Hub Card
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  HapticsService.selectionClick();
                  context.push('/collections');
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.category_rounded, color: colors.accent, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COLLECTIONS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Play All Levels',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Animals, Nature, Food, Objects, Symbols',
                              style: TextStyle(fontSize: 13, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions Grid (Tutorial, Statistics, Shop)
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.school_rounded,
                    label: 'Tutorial',
                    color: Colors.blueAccent,
                    colors: colors,
                    onTap: () => context.push('/tutorial'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Statistics',
                    color: Colors.purpleAccent,
                    colors: colors,
                    onTap: () => context.push('/statistics'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.storefront_rounded,
                    label: 'Shop',
                    color: Colors.orangeAccent,
                    colors: colors,
                    onTap: () => context.push('/shop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final PuzzleColors colors;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticsService.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
