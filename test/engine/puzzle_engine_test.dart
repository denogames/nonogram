import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/engine/game/puzzle_engine.dart';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/engine/models/cell_state.dart';
import 'package:nonogram/engine/models/grid_point.dart';

void main() {
  group('PuzzleEngine gameplay tests', () {
    late PuzzleEngine engine;

    setUp(() {
      final ascii = [
        '..#..',
        '.###.',
        '#####',
        '.###.',
        '..#..',
      ];
      final puzzle = PuzzleGenerator.fromAsciiArt(
        id: 'diamond_5x5',
        title: 'Diamond',
        category: 'symbols',
        asciiLines: ascii,
      );

      engine = PuzzleEngine(
        puzzle: puzzle,
        mistakePolicy: MistakePolicy.relax,
      );
    });

    test('Initial board state is all empty', () {
      expect(engine.isCompleted, isFalse);
      expect(engine.canUndo, isFalse);
      expect(engine.canRedo, isFalse);
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          expect(engine.getCell(r, c), CellState.empty);
        }
      }
    });

    test('Applying tools modifies cells correctly', () {
      // Toggle fill on (0, 2)
      engine.applyTool(0, 2, EditTool.fill);
      expect(engine.getCell(0, 2), CellState.filled);

      // Toggle fill again clears cell
      engine.applyTool(0, 2, EditTool.fill);
      expect(engine.getCell(0, 2), CellState.empty);

      // Toggle cross on (0, 0)
      engine.applyTool(0, 0, EditTool.cross);
      expect(engine.getCell(0, 0), CellState.crossed);

      // Erase tool
      engine.applyTool(0, 0, EditTool.erase);
      expect(engine.getCell(0, 0), CellState.empty);
    });

    test('Undo and redo restores states accurately', () {
      engine.applyTool(1, 1, EditTool.fill);
      expect(engine.getCell(1, 1), CellState.filled);
      expect(engine.canUndo, isTrue);

      engine.undo();
      expect(engine.getCell(1, 1), CellState.empty);
      expect(engine.canRedo, isTrue);

      engine.redo();
      expect(engine.getCell(1, 1), CellState.filled);
    });

    test('Batch drag stroke applies and undoes in single step', () {
      final points = [
        const GridPoint(2, 0),
        const GridPoint(2, 1),
        const GridPoint(2, 2),
      ];
      engine.applyDragStroke(points, EditTool.fill);

      expect(engine.getCell(2, 0), CellState.filled);
      expect(engine.getCell(2, 1), CellState.filled);
      expect(engine.getCell(2, 2), CellState.filled);

      // Undoing should revert all 3 cells in one undo
      engine.undo();
      expect(engine.getCell(2, 0), CellState.empty);
      expect(engine.getCell(2, 1), CellState.empty);
      expect(engine.getCell(2, 2), CellState.empty);
    });

    test('Hints never contradict solution and fix mistakes', () {
      // Intentionally make a mistake on (0, 0)
      engine.applyTool(0, 0, EditTool.fill); // solution has empty at (0, 0)

      final hintPoint = engine.provideHint();
      expect(hintPoint, isNotNull);
      expect(hintPoint, const GridPoint(0, 0));
      // Hint should have corrected (0,0) to crossed!
      expect(engine.getCell(0, 0), CellState.crossed);

      // Next hint should reveal a filled cell from solution
      final nextHint = engine.provideHint();
      expect(nextHint, isNotNull);
      expect(engine.puzzle.isSolutionFilled(nextHint!.row, nextHint.col), isTrue);
      expect(engine.getCell(nextHint.row, nextHint.col), CellState.filled);
    });

    test('Completing puzzle transitions game status to completed', () {
      final sol = engine.puzzle.solutionGrid;
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          if (sol[r][c]) {
            engine.applyTool(r, c, EditTool.fill);
          }
        }
      }

      expect(engine.isCompleted, isTrue);
      expect(engine.status, GameStatus.completed);
    });

    test('Strict mistake policy counts mistakes and corrects error', () {
      final strictEngine = PuzzleEngine(
        puzzle: engine.puzzle,
        mistakePolicy: MistakePolicy.strict,
        maxMistakesAllowed: 3,
      );

      // (0, 0) is empty in solution. If player fills it:
      strictEngine.applyTool(0, 0, EditTool.fill);
      expect(strictEngine.mistakes, 1);
      // In strict mode it automatically sets to correct state (crossed)
      expect(strictEngine.getCell(0, 0), CellState.crossed);
    });

    test('Serializing and restoring board state works deterministically', () {
      engine.applyTool(0, 2, EditTool.fill);
      engine.applyTool(0, 0, EditTool.cross);
      engine.setElapsedSeconds(42);

      final serialized = engine.serializeBoardState();
      expect(serialized.length, 25);

      final restoredEngine = PuzzleEngine(puzzle: engine.puzzle);
      restoredEngine.restoreSession(
        encodedBoard: serialized,
        mistakes: 0,
        hintsUsed: 0,
        elapsedSeconds: 42,
      );

      expect(restoredEngine.getCell(0, 2), CellState.filled);
      expect(restoredEngine.getCell(0, 0), CellState.crossed);
      expect(restoredEngine.elapsedSeconds, 42);
    });
  });
}
