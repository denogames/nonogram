import '../models/cell_state.dart';

/// Result of solving a single Nonogram line (row or column).
class LineSolveResult {
  /// Whether at least one valid clue configuration exists for this line.
  final bool hasValidSolution;

  /// Inferred cell states.
  /// If [CellState.filled], this cell MUST be filled in every valid configuration.
  /// If [CellState.crossed], this cell MUST be crossed in every valid configuration.
  /// If [CellState.empty], cell cannot be deterministically inferred yet.
  final List<CellState> deducedLine;

  /// Whether any new cells were deduced compared to input.
  final bool madeProgress;

  const LineSolveResult({
    required this.hasValidSolution,
    required this.deducedLine,
    this.madeProgress = false,
  });
}

/// Solves and deduces constraints on a single 1D line given its clues and current cell states.
class LineSolver {
  /// Deduce deterministic cell states for a line of length [length] with [clues],
  /// constrained by [currentLine].
  static LineSolveResult solveLine({
    required int length,
    required List<int> clues,
    required List<CellState> currentLine,
  }) {
    assert(currentLine.length == length, 'Line length mismatch');

    // Filter out zero clues (e.g. [0] means empty line)
    final activeClues = clues.where((c) => c > 0).toList();

    // If no clues, every cell must be crossed.
    if (activeClues.isEmpty) {
      bool conflict = false;
      final deduced = List<CellState>.filled(length, CellState.crossed);
      bool madeProgress = false;
      for (int i = 0; i < length; i++) {
        if (currentLine[i] == CellState.filled) {
          conflict = true;
          break;
        }
        if (currentLine[i] == CellState.empty) {
          madeProgress = true;
        }
      }
      return LineSolveResult(
        hasValidSolution: !conflict,
        deducedLine: conflict ? currentLine : deduced,
        madeProgress: !conflict && madeProgress,
      );
    }

    // Minimum space needed for remaining clues
    final minSpaceRemaining = List<int>.filled(activeClues.length + 1, 0);
    int sum = 0;
    for (int i = activeClues.length - 1; i >= 0; i--) {
      sum += activeClues[i] + (i < activeClues.length - 1 ? 1 : 0);
      minSpaceRemaining[i] = sum;
    }

    // Track which cell indices can be filled and which can be crossed
    final canBeFilled = List<bool>.filled(length, false);
    final canBeCrossed = List<bool>.filled(length, false);

    int validConfigurationsCount = 0;

    // Temporary line buffer for DFS
    final tempLine = List<bool>.filled(length, false); // true = filled, false = empty/crossed

    // Check if clue fits at index pos
    bool canPlaceClue(int pos, int clueLen) {
      if (pos + clueLen > length) return false;
      for (int i = 0; i < clueLen; i++) {
        if (currentLine[pos + i] == CellState.crossed) {
          return false; // Cell is already crossed, cannot be filled
        }
      }
      // Followed by at least one empty cell if not at end
      if (pos + clueLen < length && currentLine[pos + clueLen] == CellState.filled) {
        return false; // Spacer cell cannot be filled
      }
      return true;
    }

    // Depth-first search for valid line placements
    void search(int clueIdx, int cellIdx) {
      if (clueIdx == activeClues.length) {
        // All clues placed. Check if remaining cells can all be empty/crossed.
        for (int i = cellIdx; i < length; i++) {
          if (currentLine[i] == CellState.filled) {
            return; // Invalid: a required filled cell was left out
          }
          tempLine[i] = false;
        }

        // We have a valid full-line configuration!
        validConfigurationsCount++;
        for (int i = 0; i < length; i++) {
          if (tempLine[i]) {
            canBeFilled[i] = true;
          } else {
            canBeCrossed[i] = true;
          }
        }
        return;
      }

      final clue = activeClues[clueIdx];
      final minNeeded = minSpaceRemaining[clueIdx];
      final maxStart = length - minNeeded;

      for (int pos = cellIdx; pos <= maxStart; pos++) {
        // Can cellIdx .. pos-1 be crossed?
        bool gapValid = true;
        for (int k = cellIdx; k < pos; k++) {
          if (currentLine[k] == CellState.filled) {
            gapValid = false;
            break;
          }
          tempLine[k] = false;
        }
        if (!gapValid) {
          // If a filled cell was skipped, we cannot advance past it without placing a clue!
          break;
        }

        if (canPlaceClue(pos, clue)) {
          for (int k = 0; k < clue; k++) {
            tempLine[pos + k] = true;
          }
          if (pos + clue < length) {
            tempLine[pos + clue] = false;
          }

          final nextPos = (pos + clue < length) ? pos + clue + 1 : length;
          search(clueIdx + 1, nextPos);
        }
      }
    }

    search(0, 0);

    if (validConfigurationsCount == 0) {
      // Contradiction detected
      return LineSolveResult(
        hasValidSolution: false,
        deducedLine: currentLine,
        madeProgress: false,
      );
    }

    final deduced = List<CellState>.filled(length, CellState.empty);
    bool madeProgress = false;

    for (int i = 0; i < length; i++) {
      if (canBeFilled[i] && !canBeCrossed[i]) {
        deduced[i] = CellState.filled;
        if (currentLine[i] != CellState.filled) madeProgress = true;
      } else if (!canBeFilled[i] && canBeCrossed[i]) {
        deduced[i] = CellState.crossed;
        if (currentLine[i] != CellState.crossed) madeProgress = true;
      } else {
        deduced[i] = CellState.empty;
      }
    }

    return LineSolveResult(
      hasValidSolution: true,
      deducedLine: deduced,
      madeProgress: madeProgress,
    );
  }
}
