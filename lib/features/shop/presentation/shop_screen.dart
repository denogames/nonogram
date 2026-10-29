import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
import '../../../core/audio/haptics_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);
    final economy = ref.watch(economyManagerProvider);

    final isCloudSyncEnabled =
        StudioSdk.isInitialized && StudioSdk.instance.config.enableCloudSync;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Shop & Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coins & Hints Balance Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 32),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${economy.coins}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text('Coins', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: colors.gridBorder.withOpacity(0.2)),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: colors.accent, size: 32),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${economy.hintsRemaining}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text('Hints', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Only show CrossPromoBanner if cloud sync / remote liveops is enabled
            if (isCloudSyncEnabled) ...[
              const SizedBox(height: 16),
              CrossPromoBanner(service: StudioSdk.instance.crossPromoAndInbox),
            ],

            const SizedBox(height: 24),

            // Hint Packs Section (Earned Gameplay Economy)
            Text(
              'HINT PACKS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),

            _ShopItemCard(
              title: '3 Hints Pack',
              subtitle: 'Exchange 100 earned gameplay coins',
              icon: Icons.lightbulb_outline_rounded,
              priceLabel: '100 Coins',
              colors: colors,
              enabled: economy.coins >= 100,
              onBuy: () async {
                final messenger = ScaffoldMessenger.of(context);
                HapticsService.selectionClick();
                final bought = await economy.buyHintWithCoins(cost: 100, hintsToAdd: 3);
                if (bought && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('+3 Hints added to inventory!')),
                  );
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 10),

            _ShopItemCard(
              title: '10 Hints Pack',
              subtitle: 'Best value for tough 15×15 grids',
              icon: Icons.tips_and_updates_rounded,
              priceLabel: '300 Coins',
              colors: colors,
              enabled: economy.coins >= 300,
              onBuy: () async {
                final messenger = ScaffoldMessenger.of(context);
                HapticsService.selectionClick();
                final bought = await economy.buyHintWithCoins(cost: 300, hintsToAdd: 10);
                if (bought && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('+10 Hints added to inventory!')),
                  );
                  setState(() {});
                }
              },
            ),

            const SizedBox(height: 20),

            // Offline Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.clueBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.gridBorder.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.offline_pin_rounded, color: colors.textSecondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All progression and currencies are securely saved offline on your device.',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String priceLabel;
  final PuzzleColors colors;
  final bool enabled;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priceLabel,
    required this.colors,
    required this.enabled,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: enabled ? onBuy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(priceLabel, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
