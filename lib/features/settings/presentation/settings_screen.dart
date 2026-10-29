import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studio_core_sdk/studio_core_sdk.dart';
import '../../../core/audio/haptics_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/vault/game_state_vault.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engine/game/puzzle_engine.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _showResetConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Local Data?'),
        content: const Text(
          'This will clear all saved puzzle progress, best times, and reset your coins & hints to default starting amounts.\n\nYour anonymous install ID will remain intact. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticsService.heavyImpact();

      // 1. Invoke Studio Core SDK reset (preserving persistent install_id)
      if (StudioSdk.isInitialized) {
        await StudioSdk.instance.resetLocalGameData(preserveInstallId: true);
      }

      // 2. Clear crash-safe GameStateVault
      if (GameStateVault.instance.isInitialized) {
        await GameStateVault.instance.clearAll();
      }

      // 3. Clear SQLite database entries
      final db = ref.read(databaseProvider);
      await db.customStatement('DELETE FROM puzzle_progress_entries');
      await db.customStatement('DELETE FROM daily_puzzle_entries');
      await db.customStatement('DELETE FROM player_economy_entries');
      await db.customStatement('DELETE FROM entitlement_entries');

      // 4. Re-initialize economy controller to default starter state
      final economy = ref.read(economyManagerProvider);
      await economy.initialize();

      // 5. Restore default preferences
      final prefs = ref.read(preferencesProvider);
      await prefs.setMistakePolicy(MistakePolicy.relax);
      await prefs.setHapticsEnabled(true);
      await prefs.setReducedMotion(false);
      await prefs.setPrecisionInputEnabled(false);
      await prefs.setSeenTutorial(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local game data reset successfully. Defaults restored.'),
          ),
        );
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // THEMES SECTION
          _SectionHeader(title: 'THEMES & APPEARANCE', colors: colors),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final mode in NonogramThemeMode.values)
                    ListTile(
                      leading: Icon(
                        mode == themeMode
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: mode == themeMode ? colors.primary : colors.textSecondary,
                      ),
                      title: Text(
                        mode.displayName,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _getThemeDescription(mode),
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                      onTap: () {
                        HapticsService.selectionClick();
                        ref.read(themeModeProvider.notifier).setTheme(mode);
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // GAMEPLAY MODE SECTION
          _SectionHeader(title: 'GAMEPLAY & ACCESSIBILITY', colors: colors),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Relax Mode (No Mistake Penalties)', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                    'Solve at your own pace without 3-mistake game over limit',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  value: prefs.mistakePolicy == MistakePolicy.relax,
                  activeThumbColor: colors.primary,
                  onChanged: (isRelax) async {
                    HapticsService.selectionClick();
                    await prefs.setMistakePolicy(
                      isRelax ? MistakePolicy.relax : MistakePolicy.strict,
                    );
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Haptic Feedback', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                    'Tactile ticks on cell drags and successes',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  value: prefs.hapticsEnabled,
                  activeThumbColor: colors.primary,
                  onChanged: (val) async {
                    HapticsService.enabled = val;
                    await prefs.setHapticsEnabled(val);
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Reduced Motion', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                    'Minimize celebratory animations and transitions',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  value: prefs.reducedMotion,
                  activeThumbColor: colors.primary,
                  onChanged: (val) async {
                    HapticsService.selectionClick();
                    await prefs.setReducedMotion(val);
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Always Show Precision Input Mode', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                    'Enlarged row/col buttons below large 15×15 grids',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  value: prefs.precisionInputEnabled,
                  activeThumbColor: colors.primary,
                  onChanged: (val) async {
                    HapticsService.selectionClick();
                    await prefs.setPrecisionInputEnabled(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // HELP & LEARN SECTION
          _SectionHeader(title: 'HELP & SYSTEM', colors: colors),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.school_rounded, color: colors.primary),
                  title: Text('Interactive Tutorial', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                    'Learn row/column clue rules and overlap tricks',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    HapticsService.selectionClick();
                    context.push('/tutorial');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: colors.textSecondary),
                  title: Text('About Nonogram Engine', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                    'Version 1.0.0 • Pure Dart Nonogram Engine v2'
                    '${StudioSdk.isInitialized ? '\nDevice ID: ${StudioSdk.instance.installId.substring(0, 8)}...' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LOCAL DATA RESET SECTION
          _SectionHeader(title: 'DATA MANAGEMENT', colors: colors),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              title: const Text(
                'Reset Local Data',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Safely clear progress and wallet while preserving anonymous install ID',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
              onTap: () => _showResetConfirmationDialog(context),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getThemeDescription(NonogramThemeMode mode) {
    switch (mode) {
      case NonogramThemeMode.classicPaper:
        return 'Warm newspaper texture with clean ink contrast';
      case NonogramThemeMode.midnight:
        return 'Modern OLED slate with cyan highlights';
      case NonogramThemeMode.ocean:
        return 'Marine indigo background with seafoam accents';
      case NonogramThemeMode.highContrast:
        return 'Pure black & white for maximum visibility';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final PuzzleColors colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: colors.primary,
        ),
      ),
    );
  }
}
