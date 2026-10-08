import '../models/clue_data.dart';
import '../models/puzzle_definition.dart';
import '../solver/nonogram_solver.dart';
import '../validator/puzzle_validator.dart';

/// Generates and validates Nonogram puzzles from binary pixel art.
class PuzzleGenerator {
  /// Converts ASCII art strings (e.g. ['..#..', '.###.']) into a boolean matrix.
  static List<List<bool>> parseAsciiArt(List<String> lines) {
    if (lines.isEmpty) return [];
    final height = lines.length;
    final width = lines[0].length;
    final grid = <List<bool>>[];

    for (int r = 0; r < height; r++) {
      final line = lines[r];
      if (line.length != width) {
        throw ArgumentError('Inconsistent line length at row $r: expected $width, got ${line.length}');
      }
      final row = <bool>[];
      for (int c = 0; c < width; c++) {
        final ch = line[c];
        row.add(ch == '#' || ch == '1' || ch == 'X');
      }
      grid.add(row);
    }
    return grid;
  }

  /// Generates a validated [PuzzleDefinition] from a 2D boolean grid.
  static PuzzleDefinition fromGrid({
    required String id,
    required String title,
    required String category,
    Map<String, String> categoryTitles = const {},
    required List<List<bool>> grid,
    PuzzleDifficulty? overrideDifficulty,
    int revision = 1,
    int contentVersion = 1,
    PublicationStatus publicationStatus = PublicationStatus.published,
    String author = 'Antigravity Studio',
    String license = 'Proprietary',
    List<String> tags = const [],
    List<String>? colorPalette,
  }) {
    final height = grid.length;
    if (height == 0) throw ArgumentError('Grid cannot be empty');
    final width = grid[0].length;

    // 1. Calculate row clues
    final rowHints = <List<int>>[];
    for (int r = 0; r < height; r++) {
      rowHints.add(PuzzleValidator.calculateLineClues(grid[r]));
    }

    // 2. Calculate column clues
    final columnHints = <List<int>>[];
    for (int c = 0; c < width; c++) {
      final col = List<bool>.generate(height, (r) => grid[r][c]);
      columnHints.add(PuzzleValidator.calculateLineClues(col));
    }

    // 3. Encode solution string
    final solBuffer = StringBuffer();
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        solBuffer.write(grid[r][c] ? '1' : '0');
      }
    }
    final encodedSolution = solBuffer.toString();

    // 4. Calculate checksum
    final checksum = PuzzleDefinition.calculateChecksum(
      id: id,
      width: width,
      height: height,
      rowHints: rowHints,
      columnHints: columnHints,
      encodedSolution: encodedSolution,
    );

    // 5. Test uniqueness and estimate difficulty
    final clueData = ClueData(rowClues: rowHints, colClues: columnHints);
    final solver = NonogramSolver(clues: clueData, maxSolutions: 2);
    final solverResult = solver.solve();

    final difficulty = overrideDifficulty ?? solverResult.estimatedDifficulty;

    return PuzzleDefinition(
      id: id,
      revision: revision,
      title: title,
      category: category,
      categoryTitles: categoryTitles,
      width: width,
      height: height,
      rowHints: rowHints,
      columnHints: columnHints,
      encodedSolution: encodedSolution,
      difficulty: difficulty,
      contentVersion: contentVersion,
      publicationStatus: publicationStatus,
      author: author,
      license: license,
      tags: tags,
      checksum: checksum,
      colorPalette: colorPalette,
    );
  }

  /// Convenience method to create from ASCII art lines.
  static PuzzleDefinition fromAsciiArt({
    required String id,
    required String title,
    required String category,
    Map<String, String> categoryTitles = const {},
    required List<String> asciiLines,
    PuzzleDifficulty? overrideDifficulty,
    List<String> tags = const [],
    List<String>? colorPalette,
  }) {
    final grid = parseAsciiArt(asciiLines);
    return fromGrid(
      id: id,
      title: title,
      category: category,
      categoryTitles: categoryTitles,
      grid: grid,
      overrideDifficulty: overrideDifficulty,
      tags: tags,
      colorPalette: colorPalette,
    );
  }
}
