import '../../engine/models/puzzle_definition.dart';
import 'database/app_database.dart';
import 'vault/game_state_vault.dart';

/// In-progress boards are bound to the puzzle content they were played on.
///
/// A saved board is stored as `fp1:<fingerprint>:<cells>`, where the fingerprint is the
/// puzzle's validated content checksum (id, size, clues and solution; the title is not part
/// of it). When a published puzzle keeps its id and size but its solution changes, the
/// fingerprint no longer matches and the old marks are not restored. Only the board, mistakes,
/// hints used and elapsed time of the unfinished attempt are skipped; completion, stars, best
/// time and the wallet are separate records and are never touched. The saved row itself is not
/// deleted here; it is replaced by the next save of that puzzle, as with any attempt.
///
/// Boards saved before this format (plain `<cells>`) carry no fingerprint and are restored as
/// before, when their length matches the board.
class SavedBoard {
  static const _prefix = 'fp1:';

  final String? fingerprint;
  final String cells;

  const SavedBoard._(this.fingerprint, this.cells);

  /// The content fingerprint of [puzzle]: its checksum recomputed from the content, so it
  /// never depends on which loader produced the definition.
  static String fingerprintOf(PuzzleDefinition puzzle) => PuzzleDefinition.calculateChecksum(
        id: puzzle.id,
        width: puzzle.width,
        height: puzzle.height,
        rowHints: puzzle.rowHints,
        columnHints: puzzle.columnHints,
        encodedSolution: puzzle.encodedSolution,
      );

  /// What to store for an unfinished attempt at [puzzle].
  static String encode(PuzzleDefinition puzzle, String cells) => '$_prefix${fingerprintOf(puzzle)}:$cells';

  static SavedBoard parse(String raw) {
    if (raw.startsWith(_prefix)) {
      final rest = raw.substring(_prefix.length);
      final sep = rest.indexOf(':');
      if (sep > 0) return SavedBoard._(rest.substring(0, sep), rest.substring(sep + 1));
      return const SavedBoard._('', ''); // damaged: never matches a puzzle
    }
    return SavedBoard._(null, raw);
  }

  /// The cells to restore for [puzzle], or null when the saved attempt belongs to different
  /// content (or does not fit the board).
  static String? restorableCells(String? raw, PuzzleDefinition puzzle) {
    if (raw == null) return null;
    final saved = parse(raw);
    if (saved.fingerprint != null && saved.fingerprint != fingerprintOf(puzzle)) return null;
    if (saved.cells.length != puzzle.width * puzzle.height) return null;
    return saved.cells;
  }
}

/// An unfinished attempt that may be resumed on the current content of a puzzle.
class ResumableAttempt {
  final String cells;
  final int mistakes;
  final int hintsUsed;
  final int elapsedSeconds;

  const ResumableAttempt({
    required this.cells,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsedSeconds,
  });

  /// Chooses the attempt to resume for [puzzle]: the crash-safe vault first, then the
  /// database, each only when it is unfinished and was saved on the same content.
  static ResumableAttempt? choose(
    PuzzleDefinition puzzle, {
    SavedPuzzleState? vault,
    PuzzleProgressEntry? database,
  }) {
    if (vault != null && !vault.isCompleted) {
      final cells = SavedBoard.restorableCells(vault.savedBoardState, puzzle);
      if (cells != null) {
        return ResumableAttempt(
          cells: cells,
          mistakes: vault.savedMistakes,
          hintsUsed: vault.savedHintsUsed,
          elapsedSeconds: vault.savedElapsedSeconds,
        );
      }
    }
    if (database != null && !database.isCompleted) {
      final cells = SavedBoard.restorableCells(database.savedBoardState, puzzle);
      if (cells != null) {
        return ResumableAttempt(
          cells: cells,
          mistakes: database.savedMistakes,
          hintsUsed: database.savedHintsUsed,
          elapsedSeconds: database.savedElapsedSeconds,
        );
      }
    }
    return null;
  }
}
