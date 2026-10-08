import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/engine/generator/puzzle_generator.dart';
import 'package:nonogram/engine/models/clue_data.dart';
import 'package:nonogram/engine/solver/nonogram_solver.dart';
import 'package:nonogram/engine/validator/puzzle_validator.dart';

void main() {
  group('NonogramSolver tests', () {
    test('Solves a 5x5 heart puzzle with unique solution', () {
      final ascii = [
        '.#.#.',
        '#####',
        '#####',
        '.###.',
        '..#..',
      ];
      final puzzle = PuzzleGenerator.fromAsciiArt(
        id: 'heart_5x5',
        title: 'Heart',
        category: 'symbols',
        asciiLines: ascii,
      );

      final solver = NonogramSolver(clues: puzzle.clues);
      final result = solver.solve();

      expect(result.status, SolverStatus.uniqueSolution);
      expect(result.solutionCount, 1);
      expect(result.isUnique, isTrue);
      expect(result.encodedUniqueSolution, puzzle.encodedSolution);
    });

    test('Solves a 10x10 cup puzzle with verified unique solution', () {
      final ascii = [
        '..........',
        '..##..##..',
        '..##..##..',
        '..........',
        '..######..',
        '..#....#.#',
        '..#....###',
        '..#....#.#',
        '..######..',
        '..........',
      ];
      final puzzle = PuzzleGenerator.fromAsciiArt(
        id: 'cup_10x10',
        title: 'Cup',
        category: 'objects',
        asciiLines: ascii,
      );

      final solver = NonogramSolver(clues: puzzle.clues);
      final result = solver.solve();

      expect(result.status, SolverStatus.uniqueSolution);
      expect(result.solutionCount, 1);
      expect(result.encodedUniqueSolution, puzzle.encodedSolution);
    });

    test('Detects ambiguous puzzle with multiple solutions', () {
      // Classic 2x2 ambiguity inside a 5x5 grid:
      // Row clues: [1], [1], [0], [0], [0]
      // Col clues: [1], [1], [0], [0], [0]
      final clues = ClueData(
        rowClues: [
          [1],
          [1],
          [0],
          [0],
          [0],
        ],
        colClues: [
          [1],
          [1],
          [0],
          [0],
          [0],
        ],
      );

      final solver = NonogramSolver(clues: clues, maxSolutions: 2);
      final result = solver.solve();

      expect(result.status, SolverStatus.multipleSolutions);
      expect(result.solutionCount, 2);
      expect(result.isUnique, isFalse);
    });

    test('Detects contradiction with no solutions', () {
      // Row wants 5 filled, Col wants 0 filled -> impossible!
      final clues = ClueData(
        rowClues: [
          [5],
          [0],
          [0],
          [0],
          [0],
        ],
        colClues: [
          [0],
          [0],
          [0],
          [0],
          [0],
        ],
      );

      final solver = NonogramSolver(clues: clues);
      final result = solver.solve();

      expect(
        result.status == SolverStatus.invalidClues ||
            result.status == SolverStatus.noSolution,
        isTrue,
      );
      expect(result.solutionCount, 0);
    });

    test('Validates quality gate through PuzzleValidator', () {
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

      final report = PuzzleValidator.validate(puzzle);
      expect(report.passesQualityGate, isTrue);
      expect(report.isUnique, isTrue);
      expect(report.errorMessages, isEmpty);
    });
  });
}
