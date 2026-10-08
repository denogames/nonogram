import 'package:flutter/material.dart';
import '../../../../core/audio/haptics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../engine/models/cell_state.dart';

class ControlBarWidget extends StatelessWidget {
  final EditTool currentTool;
  final ValueChanged<EditTool> onToolChanged;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onHint;
  final int hintsRemaining;
  final bool isPrecisionActive;
  final VoidCallback onTogglePrecision;
  final PuzzleColors colors;

  const ControlBarWidget({
    super.key,
    required this.currentTool,
    required this.onToolChanged,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onHint,
    required this.hintsRemaining,
    required this.isPrecisionActive,
    required this.onTogglePrecision,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Undo
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo_rounded),
              color: canUndo ? colors.textPrimary : colors.textSecondary.withOpacity(0.3),
              onPressed: canUndo
                  ? () {
                      HapticsService.selectionClick();
                      onUndo();
                    }
                  : null,
            ),

            // Redo
            IconButton(
              tooltip: 'Redo',
              icon: const Icon(Icons.redo_rounded),
              color: canRedo ? colors.textPrimary : colors.textSecondary.withOpacity(0.3),
              onPressed: canRedo
                  ? () {
                      HapticsService.selectionClick();
                      onRedo();
                    }
                  : null,
            ),

            // Tool Segmented Switch (Fill, Cross, Erase)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.clueBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _ToolButton(
                    icon: Icons.square,
                    tooltip: 'Fill',
                    isSelected: currentTool == EditTool.fill,
                    colors: colors,
                    onTap: () {
                      HapticsService.selectionClick();
                      onToolChanged(EditTool.fill);
                    },
                  ),
                  const SizedBox(width: 4),
                  _ToolButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cross (X)',
                    isSelected: currentTool == EditTool.cross,
                    colors: colors,
                    onTap: () {
                      HapticsService.selectionClick();
                      onToolChanged(EditTool.cross);
                    },
                  ),
                  const SizedBox(width: 4),
                  _ToolButton(
                    icon: Icons.cleaning_services_rounded,
                    tooltip: 'Erase',
                    isSelected: currentTool == EditTool.erase,
                    colors: colors,
                    onTap: () {
                      HapticsService.selectionClick();
                      onToolChanged(EditTool.erase);
                    },
                  ),
                ],
              ),
            ),

            // Precision Mode Toggle
            IconButton(
              tooltip: 'Precision Mode',
              icon: Icon(
                Icons.center_focus_strong_rounded,
                color: isPrecisionActive ? colors.primary : colors.textSecondary,
              ),
              onPressed: () {
                HapticsService.selectionClick();
                onTogglePrecision();
              },
            ),

            // Hint Button with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Hint',
                  icon: const Icon(Icons.lightbulb_rounded),
                  color: colors.accent,
                  onPressed: () {
                    HapticsService.selectionClick();
                    onHint();
                  },
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$hintsRemaining',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final PuzzleColors colors;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
