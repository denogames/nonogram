import '../models/puzzle_definition.dart';
import '../solver/nonogram_solver.dart';

/// Validation outcome and diagnostic metrics for a Nonogram puzzle.
class PuzzleValidationReport {
  final bool isValid;
  final bool isUnique;
  final int solutionCount;
  final bool isLineSolvable;
  final PuzzleDifficulty estimatedDifficulty;
  final List<String> errorMessages;
  final List<String> warnings;

  const PuzzleValidationReport({
    required this.isValid,
    required this.isUnique,
    required this.solutionCount,
    required this.isLineSolvable,
    required this.estimatedDifficulty,
    this.errorMessages = const [],
    this.warnings = const [],
  });

  bool get passesQualityGate =>
      isValid && isUnique && solutionCount == 1 && errorMessages.isEmpty;

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('=== Nonogram Validation Report ===');
    buf.writeln('Valid: $isValid');
    buf.writeln('Unique: $isUnique (Solutions found: $solutionCount)');
    buf.writeln('Purely Line-Solvable: $isLineSolvable');
    buf.writeln('Difficulty: ${estimatedDifficulty.displayName}');
    if (errorMessages.isNotEmpty) {
      buf.writeln('Errors:');
      for (final err in errorMessages) {
        buf.writeln('  - $err');
      }
    }
    if (warnings.isNotEmpty) {
      buf.writeln('Warnings:');
      for (final w in warnings) {
        buf.writeln('  - $w');
      }
    }
    return buf.toString();
  }
}

/// Validates puzzle integrity, uniqueness, and consistency.
class PuzzleValidator {
  /// Validates an existing [PuzzleDefinition].
  static PuzzleValidationReport validate(PuzzleDefinition puzzle) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check dimensions
    if (puzzle.width < 5 || puzzle.height < 5) {
      errors.add('Board dimensions must be at least 5x5 (current: ${puzzle.width}x${puzzle.height})');
    }

    if (puzzle.rowHints.length != puzzle.height) {
      errors.add('Row hints length (${puzzle.rowHints.length}) does not match height (${puzzle.height})');
    }

    if (puzzle.columnHints.length != puzzle.width) {
      errors.add('Column hints length (${puzzle.columnHints.length}) does not match width (${puzzle.width})');
    }

    // Check encoded solution length
    if (puzzle.encodedSolution.length != puzzle.width * puzzle.height) {
      errors.add('Encoded solution length (${puzzle.encodedSolution.length}) must match width*height (${puzzle.width * puzzle.height})');
    }

    // Verify Checksum
    if (!puzzle.verifyChecksum()) {
      errors.add('Checksum verification failed');
    }

    // Check Clue consistency
    final clues = puzzle.clues;
    if (!clues.isValid()) {
      errors.add('Clues contain invalid numbers (<= 0 or empty)');
    }

    if (!clues.hasBalancedTotals) {
      errors.add('Row clue sum (${clues.totalRowFilled}) does not equal column clue sum (${clues.totalColFilled})');
    }

    // Verify solution matches clues
    final boolGrid = puzzle.solutionGrid;
    final derivedRowClues = <List<int>>[];
    for (int r = 0; r < puzzle.height; r++) {
      derivedRowClues.add(calculateLineClues(boolGrid[r]));
    }
    final derivedColClues = <List<int>>[];
    for (int c = 0; c < puzzle.width; c++) {
      final col = List<bool>.generate(puzzle.height, (r) => boolGrid[r][c]);
      derivedColClues.add(calculateLineClues(col));
    }

    if (!_listsEqual(derivedRowClues, puzzle.rowHints)) {
      errors.add('Solution does not match given row clues');
    }
    if (!_listsEqual(derivedColClues, puzzle.columnHints)) {
      errors.add('Solution does not match given column clues');
    }

    // Execute solver to check uniqueness
    final solver = NonogramSolver(clues: clues, maxSolutions: 2);
    final solverResult = solver.solve();

    if (solverResult.solutionCount == 0) {
      errors.add('Solver found 0 solutions for given clues');
    } else if (solverResult.solutionCount > 1) {
      errors.add('Ambiguous puzzle! Solver found multiple valid solutions (${solverResult.solutionCount})');
    }

    if (!solverResult.isLineSolvable) {
      warnings.add('Puzzle requires branching/guessing; not 100% line solvable');
    }

    return PuzzleValidationReport(
      isValid: errors.isEmpty,
      isUnique: solverResult.isUnique,
      solutionCount: solverResult.solutionCount,
      isLineSolvable: solverResult.isLineSolvable,
      estimatedDifficulty: solverResult.estimatedDifficulty,
      errorMessages: errors,
      warnings: warnings,
    );
  }

  /// Calculates clues for a single line of boolean filled states.
  static List<int> calculateLineClues(List<bool> line) {
    final clues = <int>[];
    int run = 0;
    for (final filled in line) {
      if (filled) {
        run++;
      } else {
        if (run > 0) {
          clues.add(run);
          run = 0;
        }
      }
    }
    if (run > 0) {
      clues.add(run);
    }
    return clues.isEmpty ? [0] : clues;
  }

  static bool _listsEqual(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final cleanA = a[i].where((x) => x > 0).toList();
      final cleanB = b[i].where((x) => x > 0).toList();
      if (cleanA.length != cleanB.length) return false;
      for (int j = 0; j < cleanA.length; j++) {
        if (cleanA[j] != cleanB[j]) return false;
      }
    }
    return true;
  }
}
