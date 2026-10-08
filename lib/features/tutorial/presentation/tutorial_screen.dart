import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/haptics_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Welcome to Nonogram!',
      'subtitle': 'A game of pure logic and pixel art',
      'icon': Icons.grid_4x4_rounded,
      'body':
          'Nonograms (also known as Picross) are picture logic puzzles where cells in a grid must be colored or left blank according to numbers at the side of the grid.',
      'diagram': 'basic_grid',
    },
    {
      'title': '1. Row & Column Clues',
      'subtitle': 'Numbers indicate filled groups',
      'icon': Icons.format_list_numbered_rounded,
      'body':
          'A clue like [3] means there are 3 consecutive filled squares in that line.\n\nMultiple numbers like [2, 1] mean a block of 2, followed by at least one empty square, and then a block of 1.',
      'diagram': 'numbers',
    },
    {
      'title': '2. Marking X on Empty Cells',
      'subtitle': 'Eliminate impossible squares',
      'icon': Icons.close_rounded,
      'body':
          'Once a group is complete, mark the remaining cells in that row or column with an X.\n\nMarking Xs prevents mistakes and helps narrow down intersecting lines!',
      'diagram': 'cross_mark',
    },
    {
      'title': '3. The Overlap Technique',
      'subtitle': 'Deduce cells before knowing the exact position',
      'icon': Icons.lightbulb_outline_rounded,
      'body':
          'In a 5-cell line with a clue of [4]:\n• Pushed left: [■, ■, ■, ■, □]\n• Pushed right: [□, ■, ■, ■, ■]\n\nNotice the middle 3 cells overlap! They MUST be filled in every scenario.',
      'diagram': 'overlap',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = PuzzleColors.getPalette(themeMode);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('How to Play', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step['icon'] as IconData, size: 40, color: colors.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              step['body'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator & Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? colors.primary : colors.clueBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        HapticsService.selectionClick();
                        if (_currentPage < _steps.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Start practice level
                          context.pushReplacement('/puzzle/tutorial_1');
                        }
                      },
                      child: Text(
                        _currentPage < _steps.length - 1 ? 'Next' : 'Start Practice Puzzle',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
