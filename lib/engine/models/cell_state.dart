/// Represents the state of a single cell in the Nonogram grid.
enum CellState {
  /// Unmarked / blank cell.
  empty,

  /// Marked as filled (part of the picture).
  filled,

  /// Marked as definitely empty / crossed out (X).
  crossed;

  /// Returns true if this cell is filled.
  bool get isFilled => this == CellState.filled;

  /// Returns true if this cell is marked with X.
  bool get isCrossed => this == CellState.crossed;

  /// Returns true if this cell is not yet marked.
  bool get isEmpty => this == CellState.empty;

  /// Encodes cell to single character representation.
  String toChar() {
    switch (this) {
      case CellState.filled:
        return '1';
      case CellState.crossed:
        return 'X';
      case CellState.empty:
        return '.';
    }
  }

  /// Parses single character to CellState.
  static CellState fromChar(String ch) {
    switch (ch) {
      case '1':
      case '#':
        return CellState.filled;
      case 'X':
      case 'x':
      case '0':
        return CellState.crossed;
      default:
        return CellState.empty;
    }
  }
}

/// Represents the interaction tool currently selected by the player.
enum EditTool {
  fill,
  cross,
  erase,
}
