import 'package:flutter/material.dart';
import '../../../../core/audio/haptics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../engine/models/puzzle_definition.dart';

class ArtworkRevealDialog extends StatefulWidget {
  final PuzzleDefinition puzzle;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final PuzzleColors colors;
  final VoidCallback onNextPuzzle;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const ArtworkRevealDialog({
    super.key,
    required this.puzzle,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.colors,
    required this.onNextPuzzle,
    required this.onReplay,
    required this.onExit,
  });

  @override
  State<ArtworkRevealDialog> createState() => _ArtworkRevealDialogState();
}

class _ArtworkRevealDialogState extends State<ArtworkRevealDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    HapticsService.successCelebration();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _calculateStars() {
    if (widget.mistakes == 0 && widget.hintsUsed == 0) return 3;
    if (widget.mistakes <= 1 && widget.hintsUsed <= 2) return 2;
    return 1;
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stars = _calculateStars();
    final grid = widget.puzzle.solutionGrid;
    final width = widget.puzzle.width;
    final height = widget.puzzle.height;

    final primaryRevealColor = (widget.puzzle.colorPalette != null &&
            widget.puzzle.colorPalette!.isNotEmpty)
        ? _parseHex(widget.puzzle.colorPalette!.first, widget.colors.primary)
        : widget.colors.primary;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'PUZZLE SOLVED!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: widget.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.puzzle.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Completed Pixel Art Canvas Presentation
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.colors.clueBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.colors.gridBorder.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: width / height,
                        child: CustomPaint(
                          painter: _RevealedArtworkPainter(
                            grid: grid,
                            width: width,
                            height: height,
                            artColor: primaryRevealColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final hasStar = i < stars;
                      return Icon(
                        hasStar ? Icons.star_rounded : Icons.star_border_rounded,
                        color: hasStar ? Colors.amber : Colors.grey.withOpacity(0.4),
                        size: 38,
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        icon: Icons.timer_outlined,
                        label: 'Time',
                        value: _formatTime(widget.elapsedSeconds),
                        colors: widget.colors,
                      ),
                      _StatItem(
                        icon: Icons.error_outline_rounded,
                        label: 'Mistakes',
                        value: '${widget.mistakes}',
                        colors: widget.colors,
                      ),
                      _StatItem(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Hints',
                        value: '${widget.hintsUsed}',
                        colors: widget.colors,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onExit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Menu'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onNextPuzzle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final PuzzleColors colors;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RevealedArtworkPainter extends CustomPainter {
  final List<List<bool>> grid;
  final int width;
  final int height;
  final Color artColor;

  _RevealedArtworkPainter({
    required this.grid,
    required this.width,
    required this.height,
    required this.artColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / width;
    final cellH = size.height / height;
    final paint = Paint()..color = artColor;

    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (grid[r][c]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
              Radius.circular(cellW * 0.15),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevealedArtworkPainter oldDelegate) => false;
}
