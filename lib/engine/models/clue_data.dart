import 'package:meta/meta.dart';

/// Encapsulates row and column clue numbers for a Nonogram puzzle.
@immutable
class ClueData {
  /// Clues for each row (indexed 0 to height - 1).
  final List<List<int>> rowClues;

  /// Clues for each column (indexed 0 to width - 1).
  final List<List<int>> colClues;

  const ClueData({
    required this.rowClues,
    required this.colClues,
  });

  int get height => rowClues.length;
  int get width => colClues.length;

  /// Validates clue structure.
  bool isValid() {
    if (rowClues.isEmpty || colClues.isEmpty) return false;
    for (final r in rowClues) {
      if (r.isEmpty) continue; // treated as [0]
      for (final n in r) {
        if (n < 0) return false;
        if (n == 0 && r.length > 1) return false; // 0 cannot be combined with other numbers
      }
    }
    for (final c in colClues) {
      if (c.isEmpty) continue;
      for (final n in c) {
        if (n < 0) return false;
        if (n == 0 && c.length > 1) return false;
      }
    }
    return true;
  }

  /// Calculates total filled cells required by rows.
  int get totalRowFilled =>
      rowClues.fold(0, (sum, list) => sum + list.fold(0, (s, n) => s + (n > 0 ? n : 0)));

  /// Calculates total filled cells required by columns.
  int get totalColFilled =>
      colClues.fold(0, (sum, list) => sum + list.fold(0, (s, n) => s + (n > 0 ? n : 0)));

  /// Checks if row sums match column sums.
  bool get hasBalancedTotals => totalRowFilled == totalColFilled;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClueData) return false;
    if (rowClues.length != other.rowClues.length ||
        colClues.length != other.colClues.length) {
      return false;
    }
    for (int i = 0; i < rowClues.length; i++) {
      if (rowClues[i].length != other.rowClues[i].length) return false;
      for (int j = 0; j < rowClues[i].length; j++) {
        if (rowClues[i][j] != other.rowClues[i][j]) return false;
      }
    }
    for (int i = 0; i < colClues.length; i++) {
      if (colClues[i].length != other.colClues[i].length) return false;
      for (int j = 0; j < colClues[i].length; j++) {
        if (colClues[i][j] != other.colClues[i][j]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(rowClues.map(Object.hashAll)),
        Object.hashAll(colClues.map(Object.hashAll)),
      );
}
