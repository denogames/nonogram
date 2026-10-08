import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/core/providers/app_providers.dart';
import 'package:nonogram/core/storage/database/app_database.dart';
import 'package:nonogram/core/storage/preferences/app_preferences.dart';
import 'package:nonogram/core/theme/app_theme.dart';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/engine/models/cell_state.dart';
import 'package:nonogram/features/collections/domain/puzzle_repository.dart';
import 'package:nonogram/features/puzzle_game/presentation/widgets/control_bar_widget.dart';
import 'package:nonogram/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App mounts and displays Home Screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();
    final database = AppDatabase(NativeDatabase.memory());
    final repo = PuzzleRepository();

    // Register a starter puzzle
    repo.registerPuzzles([
      PuzzleGenerator.fromAsciiArt(
        id: 'cat_5x5',
        title: 'Cat',
        category: 'animals',
        asciiLines: [
          '#...#',
          '#####',
          '##.##',
          '.###.',
          '..#..',
        ],
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          preferencesProvider.overrideWithValue(prefs),
          puzzleRepositoryProvider.overrideWithValue(repo),
        ],
        child: const NonogramApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NONOGRAM'), findsOneWidget);
    expect(find.text('DAILY PUZZLE'), findsOneWidget);
    expect(find.text('COLLECTIONS'), findsOneWidget);

    await database.close();
  });

  testWidgets('ControlBarWidget handles tool switching and callbacks', (WidgetTester tester) async {
    EditTool currentTool = EditTool.fill;
    bool undoCalled = false;
    bool hintCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ControlBarWidget(
                currentTool: currentTool,
                onToolChanged: (tool) {
                  setState(() => currentTool = tool);
                },
                canUndo: true,
                canRedo: false,
                onUndo: () => undoCalled = true,
                onRedo: () {},
                onHint: () => hintCalled = true,
                hintsRemaining: 5,
                isPrecisionActive: false,
                onTogglePrecision: () {},
                colors: PuzzleColors.classicPaper,
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify tools present
    expect(find.byTooltip('Fill'), findsOneWidget);
    expect(find.byTooltip('Cross (X)'), findsOneWidget);
    expect(find.byTooltip('Erase'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Hint'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Switch to cross tool
    await tester.tap(find.byTooltip('Cross (X)'));
    await tester.pumpAndSettle();
    expect(currentTool, EditTool.cross);

    // Tap Undo
    await tester.tap(find.byTooltip('Undo'));
    expect(undoCalled, isTrue);

    // Tap Hint
    await tester.tap(find.byTooltip('Hint'));
    expect(hintCalled, isTrue);
  });
}
