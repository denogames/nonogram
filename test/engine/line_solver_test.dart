import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/engine/models/cell_state.dart';
import 'package:nonogram/engine/solver/line_solver.dart';

void main() {
  group('LineSolver tests', () {
    test('Empty clue on line of 5 means all cells are crossed', () {
      final line = List.filled(5, CellState.empty);
      final res = LineSolver.solveLine(
        length: 5,
        clues: [],
        currentLine: line,
      );

      expect(res.hasValidSolution, isTrue);
      expect(res.deducedLine, List.filled(5, CellState.crossed));
    });

    test('Full line clue [5] on line of 5 means all cells are filled', () {
      final line = List.filled(5, CellState.empty);
      final res = LineSolver.solveLine(
        length: 5,
        clues: [5],
        currentLine: line,
      );

      expect(res.hasValidSolution, isTrue);
      expect(res.deducedLine, List.filled(5, CellState.filled));
    });

    test('Overlap clue [3] on line of 5 deduces center cell is filled', () {
      // For clue 3 on length 5:
      // placements: [1,1,1,0,0], [0,1,1,1,0], [0,0,1,1,1]
      // intersection is index 2 (center cell)
      final line = List.filled(5, CellState.empty);
      final res = LineSolver.solveLine(
        length: 5,
        clues: [3],
        currentLine: line,
      );

      expect(res.hasValidSolution, isTrue);
      expect(res.deducedLine[2], CellState.filled);
      expect(res.deducedLine[0], CellState.empty);
      expect(res.deducedLine[4], CellState.empty);
    });

    test('Exact fit clue [2, 2] on line of 5 determines entire line', () {
      // 2 + 1 (spacer) + 2 = 5
      final line = List.filled(5, CellState.empty);
      final res = LineSolver.solveLine(
        length: 5,
        clues: [2, 2],
        currentLine: line,
      );

      expect(res.hasValidSolution, isTrue);
      expect(res.deducedLine, [
        CellState.filled,
        CellState.filled,
        CellState.crossed,
        CellState.filled,
        CellState.filled,
      ]);
    });

    test('Detects contradiction when clue cannot fit given crossed cells', () {
      // Clue is 4, but center is crossed: [., ., X, ., .]
      // Cannot place 4 consecutive filled cells!
      final line = [
        CellState.empty,
        CellState.empty,
        CellState.crossed,
        CellState.empty,
        CellState.empty,
      ];
      final res = LineSolver.solveLine(
        length: 5,
        clues: [4],
        currentLine: line,
      );

      expect(res.hasValidSolution, isFalse);
    });
  });
}
