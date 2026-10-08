import 'package:meta/meta.dart';
import 'cell_state.dart';
import 'grid_point.dart';

/// Represents a change to a single cell on the board.
@immutable
class CellChange {
  final GridPoint point;
  final CellState oldState;
  final CellState newState;

  const CellChange({
    required this.point,
    required this.oldState,
    required this.newState,
  });

  int get row => point.row;
  int get col => point.col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellChange &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          oldState == other.oldState &&
          newState == other.newState;

  @override
  int get hashCode => Object.hash(point, oldState, newState);

  @override
  String toString() => 'CellChange($point: $oldState -> $newState)';
}

/// Represents an undoable player action (which may encompass a drag across several cells).
class GameMove {
  final List<CellChange> changes;
  final DateTime timestamp;

  GameMove({
    required this.changes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isEmpty => changes.isEmpty;
  bool get isNotEmpty => changes.isNotEmpty;
}
