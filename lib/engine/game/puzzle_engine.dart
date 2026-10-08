import '../models/cell_state.dart';
import '../models/grid_point.dart';
import '../models/move_action.dart';
import '../models/puzzle_definition.dart';
import '../validator/puzzle_validator.dart';

enum GameStatus {
  inProgress,
  completed,
  failed,
}

enum MistakePolicy {
  strict,
  relax,
}

/// Core Nonogram runtime game engine.
/// Manages board state, moves, undo/redo, hints, mistake detection, and completion checking.
class PuzzleEngine {
  final PuzzleDefinition puzzle;
  final MistakePolicy mistakePolicy;
  final int maxMistakesAllowed;

  late List<List<CellState>> _board;
  final List<GameMove> _undoStack = [];
  final List<GameMove> _redoStack = [];

  GameStatus _status = GameStatus.inProgress;
  int _mistakes = 0;
  int _hintsUsed = 0;
  int _elapsedSeconds = 0;

  PuzzleEngine({
    required this.puzzle,
    this.mistakePolicy = MistakePolicy.relax,
    this.maxMistakesAllowed = 3,
  }) {
    _initBoard();
  }

  void _initBoard() {
    _board = List.generate(
      puzzle.height,
      (_) => List<CellState>.filled(puzzle.width, CellState.empty),
    );
  }

  int get width => puzzle.width;
  int get height => puzzle.height;
  GameStatus get status => _status;
  bool get isCompleted => _status == GameStatus.completed;
  bool get isFailed => _status == GameStatus.failed;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  int get elapsedSeconds => _elapsedSeconds;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void tickTimer() {
    if (_status == GameStatus.inProgress) {
      _elapsedSeconds++;
    }
  }

  void setElapsedSeconds(int seconds) {
    _elapsedSeconds = seconds;
  }

  /// Get state of a specific cell.
  CellState getCell(int row, int col) {
    if (row < 0 || row >= height || col < 0 || col >= width) {
      return CellState.empty;
    }
    return _board[row][col];
  }

  /// Read-only snapshot of current board.
  List<List<CellState>> get board =>
      _board.map((row) => List<CellState>.from(row)).toList();

  /// Applies a single cell change or toggle according to [tool].
  /// Returns the changed cell or null if no change occurred.
  CellChange? applyTool(int row, int col, EditTool tool) {
    if (_status != GameStatus.inProgress) return null;
    if (row < 0 || row >= height || col < 0 || col >= width) return null;

    final current = _board[row][col];
    final CellState targetState;

    switch (tool) {
      case EditTool.fill:
        targetState = current == CellState.filled ? CellState.empty : CellState.filled;
        break;
      case EditTool.cross:
        targetState = current == CellState.crossed ? CellState.empty : CellState.crossed;
        break;
      case EditTool.erase:
        targetState = CellState.empty;
        break;
    }

    if (targetState == current) return null;

    final change = _applyChangeInternal(row, col, targetState);
    if (change != null) {
      _undoStack.add(GameMove(changes: [change]));
      _redoStack.clear();
      _checkCompletion();
    }
    return change;
  }

  /// Applies a batch stroke (e.g., from drag gesture) of points.
  /// If [forcedState] is provided, sets all touched cells to that state.
  /// Otherwise infers target state from tool and the first touched cell.
  List<CellChange> applyDragStroke(List<GridPoint> points, EditTool tool) {
    if (_status != GameStatus.inProgress || points.isEmpty) return [];

    final first = points.first;
    final firstCurrent = getCell(first.row, first.col);

    final CellState targetState;
    switch (tool) {
      case EditTool.fill:
        targetState = firstCurrent == CellState.filled ? CellState.empty : CellState.filled;
        break;
      case EditTool.cross:
        targetState = firstCurrent == CellState.crossed ? CellState.empty : CellState.crossed;
        break;
      case EditTool.erase:
        targetState = CellState.empty;
        break;
    }

    final changes = <CellChange>[];
    for (final pt in points) {
      if (pt.row < 0 || pt.row >= height || pt.col < 0 || pt.col >= width) continue;
      if (_board[pt.row][pt.col] != targetState) {
        final change = _applyChangeInternal(pt.row, pt.col, targetState);
        if (change != null) {
          changes.add(change);
        }
      }
    }

    if (changes.isNotEmpty) {
      _undoStack.add(GameMove(changes: changes));
      _redoStack.clear();
      _checkCompletion();
    }

    return changes;
  }

  CellChange? _applyChangeInternal(int row, int col, CellState newState) {
    final oldState = _board[row][col];
    if (oldState == newState) return null;

    // Check for mistake if strict policy and setting a marked state
    if (mistakePolicy == MistakePolicy.strict && newState != CellState.empty) {
      final shouldBeFilled = puzzle.isSolutionFilled(row, col);
      final isMistake = (newState == CellState.filled && !shouldBeFilled) ||
          (newState == CellState.crossed && shouldBeFilled);

      if (isMistake) {
        _mistakes++;
        // In strict mode, automatically correct cell to crossed if it wasn't filled
        final correctedState = shouldBeFilled ? CellState.filled : CellState.crossed;
        _board[row][col] = correctedState;

        if (maxMistakesAllowed > 0 && _mistakes >= maxMistakesAllowed) {
          _status = GameStatus.failed;
        }

        return CellChange(
          point: GridPoint(row, col),
          oldState: oldState,
          newState: correctedState,
        );
      }
    }

    _board[row][col] = newState;
    return CellChange(
      point: GridPoint(row, col),
      oldState: oldState,
      newState: newState,
    );
  }

  /// Undoes the last move (or batch move).
  bool undo() {
    if (_undoStack.isEmpty || _status == GameStatus.completed) return false;
    final move = _undoStack.removeLast();

    for (final change in move.changes.reversed) {
      _board[change.row][change.col] = change.oldState;
    }

    _redoStack.add(move);
    return true;
  }

  /// Redoes the last undone move.
  bool redo() {
    if (_redoStack.isEmpty || _status == GameStatus.completed) return false;
    final move = _redoStack.removeLast();

    for (final change in move.changes) {
      _board[change.row][change.col] = change.newState;
    }

    _undoStack.add(move);
    _checkCompletion();
    return true;
  }

  /// Provides a guaranteed logical hint that never contradicts the solution.
  /// Reveals a cell that is currently incorrect or empty.
  GridPoint? provideHint() {
    if (_status != GameStatus.inProgress) return null;

    // 1. Look for any existing mistake on the board
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final current = _board[r][c];
        if (current == CellState.empty) continue;
        final isSolFilled = puzzle.isSolutionFilled(r, c);
        if ((current == CellState.filled && !isSolFilled) ||
            (current == CellState.crossed && isSolFilled)) {
          // Fix this mistake
          final correctState = isSolFilled ? CellState.filled : CellState.crossed;
          final change = CellChange(
            point: GridPoint(r, c),
            oldState: current,
            newState: correctState,
          );
          _board[r][c] = correctState;
          _undoStack.add(GameMove(changes: [change]));
          _redoStack.clear();
          _hintsUsed++;
          _checkCompletion();
          return GridPoint(r, c);
        }
      }
    }

    // 2. Find an empty cell that belongs to the filled solution
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (_board[r][c] == CellState.empty && puzzle.isSolutionFilled(r, c)) {
          final change = CellChange(
            point: GridPoint(r, c),
            oldState: CellState.empty,
            newState: CellState.filled,
          );
          _board[r][c] = CellState.filled;
          _undoStack.add(GameMove(changes: [change]));
          _redoStack.clear();
          _hintsUsed++;
          _checkCompletion();
          return GridPoint(r, c);
        }
      }
    }

    // 3. Find any remaining empty cell and cross it out
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (_board[r][c] == CellState.empty) {
          final isSolFilled = puzzle.isSolutionFilled(r, c);
          final target = isSolFilled ? CellState.filled : CellState.crossed;
          final change = CellChange(
            point: GridPoint(r, c),
            oldState: CellState.empty,
            newState: target,
          );
          _board[r][c] = target;
          _undoStack.add(GameMove(changes: [change]));
          _redoStack.clear();
          _hintsUsed++;
          _checkCompletion();
          return GridPoint(r, c);
        }
      }
    }

    return null;
  }

  /// Checks if puzzle is completed.
  /// Puzzle is completed when all cells that should be filled are filled,
  /// and NO cell that should NOT be filled is marked as filled.
  bool _checkCompletion() {
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final isFilled = _board[r][c] == CellState.filled;
        final shouldBeFilled = puzzle.isSolutionFilled(r, c);
        if (isFilled != shouldBeFilled) {
          return false;
        }
      }
    }

    // Auto-fill all remaining empty cells with crossed for clean presentation!
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (_board[r][c] == CellState.empty) {
          _board[r][c] = CellState.crossed;
        }
      }
    }

    _status = GameStatus.completed;
    return true;
  }

  /// Returns true if row [r] matches row clues completely.
  bool isRowCompleted(int r) {
    if (r < 0 || r >= height) return false;
    final row = _board[r];
    final clues = PuzzleValidator.calculateLineClues(
      row.map((c) => c == CellState.filled).toList(),
    );
    final targetClues = puzzle.rowHints[r];
    final cleanA = clues.where((x) => x > 0).toList();
    final cleanB = targetClues.where((x) => x > 0).toList();
    if (cleanA.length != cleanB.length) return false;
    for (int i = 0; i < cleanA.length; i++) {
      if (cleanA[i] != cleanB[i]) return false;
    }
    return true;
  }

  /// Returns true if column [c] matches column clues completely.
  bool isColCompleted(int c) {
    if (c < 0 || c >= width) return false;
    final col = List<bool>.generate(height, (r) => _board[r][c] == CellState.filled);
    final clues = PuzzleValidator.calculateLineClues(col);
    final targetClues = puzzle.columnHints[c];
    final cleanA = clues.where((x) => x > 0).toList();
    final cleanB = targetClues.where((x) => x > 0).toList();
    if (cleanA.length != cleanB.length) return false;
    for (int i = 0; i < cleanA.length; i++) {
      if (cleanA[i] != cleanB[i]) return false;
    }
    return true;
  }

  /// Serializes current board state to compact string (e.g. for database persistence).
  String serializeBoardState() {
    final buffer = StringBuffer();
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        buffer.write(_board[r][c].toChar());
      }
    }
    return buffer.toString();
  }

  /// Restores board state from compact string.
  void restoreBoardState(String encoded) {
    if (encoded.length != width * height) return;
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        _board[r][c] = CellState.fromChar(encoded[r * width + c]);
      }
    }
    _checkCompletion();
  }

  /// Restores complete session state.
  void restoreSession({
    required String encodedBoard,
    required int mistakes,
    required int hintsUsed,
    required int elapsedSeconds,
  }) {
    restoreBoardState(encodedBoard);
    _mistakes = mistakes;
    _hintsUsed = hintsUsed;
    _elapsedSeconds = elapsedSeconds;
  }
}
