import '../models/cell_state.dart';
import '../models/clue_data.dart';
import '../models/grid_point.dart';
import '../models/puzzle_definition.dart';
import 'line_solver.dart';

/// Status of solver execution.
enum SolverStatus {
  uniqueSolution,
  noSolution,
  multipleSolutions,
  invalidClues,
}

/// Metrics and solutions resulting from Nonogram solver execution.
class SolverResult {
  final SolverStatus status;
  final int solutionCount;
  final List<List<List<bool>>> solutions;
  final bool isLineSolvable;
  final int logicalDeductions;
  final int lineSweeps;
  final int branchCount;
  final PuzzleDifficulty estimatedDifficulty;

  const SolverResult({
    required this.status,
    required this.solutionCount,
    this.solutions = const [],
    required this.isLineSolvable,
    required this.logicalDeductions,
    required this.lineSweeps,
    required this.branchCount,
    required this.estimatedDifficulty,
  });

  bool get isUnique => status == SolverStatus.uniqueSolution;

  /// Returns the single solution if unique, otherwise null.
  List<List<bool>>? get uniqueSolution =>
      isUnique && solutions.isNotEmpty ? solutions.first : null;

  /// Returns encoded string ('0' and '1') for unique solution if present.
  String? get encodedUniqueSolution {
    final sol = uniqueSolution;
    if (sol == null) return null;
    final buffer = StringBuffer();
    for (final row in sol) {
      for (final cell in row) {
        buffer.write(cell ? '1' : '0');
      }
    }
    return buffer.toString();
  }
}

/// Robust solver for Nonogram puzzles.
/// Resolves grids using pure line-by-line logical deduction first,
/// and branches with backtracking when necessary to count total solutions up to [maxSolutions].
class NonogramSolver {
  final ClueData clues;
  final int maxSolutions;

  NonogramSolver({
    required this.clues,
    this.maxSolutions = 2,
  });

  int get height => clues.height;
  int get width => clues.width;

  /// Solves the Nonogram puzzle and evaluates uniqueness and difficulty.
  SolverResult solve() {
    if (!clues.isValid() || !clues.hasBalancedTotals) {
      return const SolverResult(
        status: SolverStatus.invalidClues,
        solutionCount: 0,
        isLineSolvable: false,
        logicalDeductions: 0,
        lineSweeps: 0,
        branchCount: 0,
        estimatedDifficulty: PuzzleDifficulty.easy,
      );
    }

    final initialBoard = List.generate(
      height,
      (_) => List<CellState>.filled(width, CellState.empty),
    );

    int totalDeductions = 0;
    int lineSweeps = 0;
    int branchCount = 0;

    // Phase 1: Pure logical line-solving deduction
    final deductionResult = _propagateDeductions(initialBoard);
    totalDeductions = deductionResult.deductionsCount;
    lineSweeps = deductionResult.sweepCount;

    if (!deductionResult.isValid) {
      return SolverResult(
        status: SolverStatus.noSolution,
        solutionCount: 0,
        isLineSolvable: false,
        logicalDeductions: totalDeductions,
        lineSweeps: lineSweeps,
        branchCount: 0,
        estimatedDifficulty: PuzzleDifficulty.easy,
      );
    }

    // Check if fully solved by line deduction
    final board = deductionResult.board;
    if (_isBoardComplete(board)) {
      final sol = _boardToBoolGrid(board);
      return SolverResult(
        status: SolverStatus.uniqueSolution,
        solutionCount: 1,
        solutions: [sol],
        isLineSolvable: true,
        logicalDeductions: totalDeductions,
        lineSweeps: lineSweeps,
        branchCount: 0,
        estimatedDifficulty: _estimateDifficulty(
          isLineSolvable: true,
          sweeps: lineSweeps,
          deductions: totalDeductions,
          branches: 0,
          totalCells: width * height,
        ),
      );
    }

    // Phase 2: If undetermined cells remain, explore solutions via backtracking
    final foundSolutions = <List<List<bool>>>[];

    void backtrack(List<List<CellState>> currentBoard) {
      if (foundSolutions.length >= maxSolutions) return;

      final nextPoint = _findBestCandidateCell(currentBoard);
      if (nextPoint == null) {
        if (_isBoardComplete(currentBoard) && _verifySolution(currentBoard)) {
          foundSolutions.add(_boardToBoolGrid(currentBoard));
        }
        return;
      }

      branchCount++;

      // Try filled first, then crossed
      for (final trialState in [CellState.filled, CellState.crossed]) {
        if (foundSolutions.length >= maxSolutions) return;

        final branchBoard = _cloneBoard(currentBoard);
        branchBoard[nextPoint.row][nextPoint.col] = trialState;

        final prop = _propagateDeductions(branchBoard);
        if (prop.isValid) {
          if (_isBoardComplete(prop.board)) {
            if (_verifySolution(prop.board)) {
              foundSolutions.add(_boardToBoolGrid(prop.board));
            }
          } else {
            backtrack(prop.board);
          }
        }
      }
    }

    backtrack(board);

    final SolverStatus finalStatus;
    if (foundSolutions.isEmpty) {
      finalStatus = SolverStatus.noSolution;
    } else if (foundSolutions.length == 1) {
      finalStatus = SolverStatus.uniqueSolution;
    } else {
      finalStatus = SolverStatus.multipleSolutions;
    }

    return SolverResult(
      status: finalStatus,
      solutionCount: foundSolutions.length,
      solutions: foundSolutions,
      isLineSolvable: false,
      logicalDeductions: totalDeductions,
      lineSweeps: lineSweeps,
      branchCount: branchCount,
      estimatedDifficulty: _estimateDifficulty(
        isLineSolvable: false,
        sweeps: lineSweeps,
        deductions: totalDeductions,
        branches: branchCount,
        totalCells: width * height,
      ),
    );
  }

  /// Iteratively solves rows and columns until a fixed point is reached or a conflict is detected.
  _PropagationResult _propagateDeductions(List<List<CellState>> initialBoard) {
    final board = _cloneBoard(initialBoard);
    final dirtyRows = List<bool>.filled(height, true);
    final dirtyCols = List<bool>.filled(width, true);

    int deductions = 0;
    int sweeps = 0;
    bool progress = true;

    while (progress) {
      progress = false;
      sweeps++;

      // Process dirty rows
      for (int r = 0; r < height; r++) {
        if (!dirtyRows[r]) continue;
        dirtyRows[r] = false;

        final rowCells = board[r];
        final rowResult = LineSolver.solveLine(
          length: width,
          clues: clues.rowClues[r],
          currentLine: rowCells,
        );

        if (!rowResult.hasValidSolution) {
          return _PropagationResult(
            isValid: false,
            board: board,
            deductionsCount: deductions,
            sweepCount: sweeps,
          );
        }

        for (int c = 0; c < width; c++) {
          final newState = rowResult.deducedLine[c];
          if (newState != CellState.empty && board[r][c] == CellState.empty) {
            board[r][c] = newState;
            dirtyCols[c] = true;
            deductions++;
            progress = true;
          }
        }
      }

      // Process dirty columns
      for (int c = 0; c < width; c++) {
        if (!dirtyCols[c]) continue;
        dirtyCols[c] = false;

        final colCells = List<CellState>.generate(height, (r) => board[r][c]);
        final colResult = LineSolver.solveLine(
          length: height,
          clues: clues.colClues[c],
          currentLine: colCells,
        );

        if (!colResult.hasValidSolution) {
          return _PropagationResult(
            isValid: false,
            board: board,
            deductionsCount: deductions,
            sweepCount: sweeps,
          );
        }

        for (int r = 0; r < height; r++) {
          final newState = colResult.deducedLine[r];
          if (newState != CellState.empty && board[r][c] == CellState.empty) {
            board[r][c] = newState;
            dirtyRows[r] = true;
            deductions++;
            progress = true;
          }
        }
      }
    }

    return _PropagationResult(
      isValid: true,
      board: board,
      deductionsCount: deductions,
      sweepCount: sweeps,
    );
  }

  /// Selects the best candidate cell to branch on (heuristically: cell with max adjacent determined cells).
  GridPoint? _findBestCandidateCell(List<List<CellState>> board) {
    GridPoint? bestPoint;
    int maxDeterminedInCross = -1;

    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (board[r][c] == CellState.empty) {
          int count = 0;
          for (int cc = 0; cc < width; cc++) {
            if (board[r][cc] != CellState.empty) count++;
          }
          for (int rr = 0; rr < height; rr++) {
            if (board[rr][c] != CellState.empty) count++;
          }
          if (count > maxDeterminedInCross) {
            maxDeterminedInCross = count;
            bestPoint = GridPoint(r, c);
          }
        }
      }
    }
    return bestPoint;
  }

  bool _isBoardComplete(List<List<CellState>> board) {
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (board[r][c] == CellState.empty) return false;
      }
    }
    return true;
  }

  /// Verifies complete board directly against row and column clues.
  bool _verifySolution(List<List<CellState>> board) {
    for (int r = 0; r < height; r++) {
      final actualRow = _extractLineClues(board[r]);
      if (!_cluesMatch(actualRow, clues.rowClues[r])) return false;
    }
    for (int c = 0; c < width; c++) {
      final col = List<CellState>.generate(height, (r) => board[r][c]);
      final actualCol = _extractLineClues(col);
      if (!_cluesMatch(actualCol, clues.colClues[c])) return false;
    }
    return true;
  }

  static List<int> _extractLineClues(List<CellState> line) {
    final res = <int>[];
    int currentRun = 0;
    for (final cell in line) {
      if (cell == CellState.filled) {
        currentRun++;
      } else {
        if (currentRun > 0) {
          res.add(currentRun);
          currentRun = 0;
        }
      }
    }
    if (currentRun > 0) {
      res.add(currentRun);
    }
    return res.isEmpty ? [0] : res;
  }

  static bool _cluesMatch(List<int> a, List<int> b) {
    final cleanA = a.where((x) => x > 0).toList();
    final cleanB = b.where((x) => x > 0).toList();
    if (cleanA.length != cleanB.length) return false;
    for (int i = 0; i < cleanA.length; i++) {
      if (cleanA[i] != cleanB[i]) return false;
    }
    return true;
  }

  static List<List<CellState>> _cloneBoard(List<List<CellState>> src) {
    return src.map((row) => List<CellState>.from(row)).toList();
  }

  static List<List<bool>> _boardToBoolGrid(List<List<CellState>> board) {
    return board
        .map((row) => row.map((c) => c == CellState.filled).toList())
        .toList();
  }

  static PuzzleDifficulty _estimateDifficulty({
    required bool isLineSolvable,
    required int sweeps,
    required int deductions,
    required int branches,
    required int totalCells,
  }) {
    if (totalCells <= 25) {
      return PuzzleDifficulty.easy;
    }
    if (isLineSolvable) {
      if (totalCells <= 100 && sweeps <= 4) {
        return PuzzleDifficulty.easy;
      } else if (sweeps <= 7) {
        return PuzzleDifficulty.medium;
      } else {
        return PuzzleDifficulty.hard;
      }
    } else {
      if (branches <= 4) {
        return PuzzleDifficulty.hard;
      } else {
        return PuzzleDifficulty.expert;
      }
    }
  }
}

class _PropagationResult {
  final bool isValid;
  final List<List<CellState>> board;
  final int deductionsCount;
  final int sweepCount;

  _PropagationResult({
    required this.isValid,
    required this.board,
    required this.deductionsCount,
    required this.sweepCount,
  });
}
