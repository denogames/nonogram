import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/audio/haptics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../engine/game/puzzle_engine.dart';
import '../../../../engine/models/cell_state.dart';
import '../../../../engine/models/grid_point.dart';
import 'puzzle_board_painter.dart';

enum DragAxisLock { none, horizontal, vertical }

class PuzzleBoardWidget extends StatefulWidget {
  final PuzzleEngine engine;
  final PuzzleColors colors;
  final EditTool currentTool;
  final bool isPrecisionMode;
  final VoidCallback onBoardModified;

  const PuzzleBoardWidget({
    super.key,
    required this.engine,
    required this.colors,
    required this.currentTool,
    this.isPrecisionMode = false,
    required this.onBoardModified,
  });

  @override
  State<PuzzleBoardWidget> createState() => _PuzzleBoardWidgetState();
}

class _PuzzleBoardWidgetState extends State<PuzzleBoardWidget> {
  final TransformationController _transformController = TransformationController();

  int? _activeRow;
  int? _activeCol;

  // Drag tracking
  GridPoint? _dragStartPoint;
  GridPoint? _lastTouchedPoint;
  DragAxisLock _dragLock = DragAxisLock.none;
  final Set<GridPoint> _visitedInDrag = {};

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _calculateMetrics(
    BoxConstraints constraints,
    outMetrics,
  ) {
    final width = widget.engine.width;
    final height = widget.engine.height;

    // Clue area proportions
    final maxColClueCount = widget.engine.puzzle.columnHints.fold(
      1,
      (max, list) => math.max(max, list.length),
    );
    final maxRowClueCount = widget.engine.puzzle.rowHints.fold(
      1,
      (max, list) => math.max(max, list.length),
    );

    final clueAreaHeight = (maxColClueCount * 16.0 + 12.0).clamp(36.0, 90.0);
    final clueAreaWidth = (maxRowClueCount * 18.0 + 14.0).clamp(42.0, 100.0);

    final availableWidth = constraints.maxWidth - clueAreaWidth - 16;
    final availableHeight = constraints.maxHeight - clueAreaHeight - 16;

    final cellW = availableWidth / width;
    final cellH = availableHeight / height;
    final cellSize = math.min(cellW, cellH).clamp(20.0, 50.0);

    outMetrics.cellSize = cellSize;
    outMetrics.clueAreaWidth = clueAreaWidth;
    outMetrics.clueAreaHeight = clueAreaHeight;
  }

  GridPoint? _pointFromLocalOffset(
    Offset offset,
    double cellSize,
    double clueAreaWidth,
    double clueAreaHeight,
  ) {
    final x = offset.dx - clueAreaWidth;
    final y = offset.dy - clueAreaHeight;

    if (x < 0 || y < 0) return null;

    final col = (x / cellSize).floor();
    final row = (y / cellSize).floor();

    if (row >= 0 && row < widget.engine.height && col >= 0 && col < widget.engine.width) {
      return GridPoint(row, col);
    }
    return null;
  }

  // Linear interpolation between two grid points to prevent skipped cells on fast drag
  List<GridPoint> _interpolatePoints(GridPoint from, GridPoint to) {
    final points = <GridPoint>[];
    int r0 = from.row;
    int c0 = from.col;
    final r1 = to.row;
    final c1 = to.col;

    final dr = (r1 - r0).abs();
    final dc = (c1 - c0).abs();
    final stepR = r0 < r1 ? 1 : -1;
    final stepC = c0 < c1 ? 1 : -1;

    int err = dr - dc;

    while (true) {
      points.add(GridPoint(r0, c0));
      if (r0 == r1 && c0 == c1) break;
      final e2 = 2 * err;
      if (e2 > -dc) {
        err -= dc;
        r0 += stepR;
      }
      if (e2 < dr) {
        err += dr;
        c0 += stepC;
      }
    }
    return points;
  }

  void _onPanStart(
    DragStartDetails details,
    double cellSize,
    double clueAreaWidth,
    double clueAreaHeight,
  ) {
    if (widget.engine.isCompleted) return;

    final pt = _pointFromLocalOffset(
      details.localPosition,
      cellSize,
      clueAreaWidth,
      clueAreaHeight,
    );
    if (pt == null) return;

    _dragStartPoint = pt;
    _lastTouchedPoint = pt;
    _dragLock = DragAxisLock.none;
    _visitedInDrag.clear();
    _visitedInDrag.add(pt);

    setState(() {
      _activeRow = pt.row;
      _activeCol = pt.col;
    });

    final change = widget.engine.applyTool(pt.row, pt.col, widget.currentTool);
    if (change != null) {
      HapticsService.lightImpact();
      widget.onBoardModified();
    }
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    double cellSize,
    double clueAreaWidth,
    double clueAreaHeight,
  ) {
    if (widget.engine.isCompleted || _dragStartPoint == null) return;

    var pt = _pointFromLocalOffset(
      details.localPosition,
      cellSize,
      clueAreaWidth,
      clueAreaHeight,
    );
    if (pt == null) return;

    // Cardinal axis lock prevention for accidental diagonal dragging
    if (_dragLock == DragAxisLock.none) {
      final dr = (pt.row - _dragStartPoint!.row).abs();
      final dc = (pt.col - _dragStartPoint!.col).abs();
      if (dr > 0 && dr >= dc) {
        _dragLock = DragAxisLock.vertical;
      } else if (dc > 0 && dc > dr) {
        _dragLock = DragAxisLock.horizontal;
      }
    }

    // Apply locked coordinate
    if (_dragLock == DragAxisLock.horizontal) {
      pt = GridPoint(_dragStartPoint!.row, pt.col);
    } else if (_dragLock == DragAxisLock.vertical) {
      pt = GridPoint(pt.row, _dragStartPoint!.col);
    }

    if (pt != _lastTouchedPoint) {
      final path = _interpolatePoints(_lastTouchedPoint!, pt);
      final unvisited = path.where((p) => !_visitedInDrag.contains(p)).toList();

      if (unvisited.isNotEmpty) {
        for (final p in unvisited) {
          _visitedInDrag.add(p);
        }
        widget.engine.applyDragStroke(unvisited, widget.currentTool);
        HapticsService.lightImpact();
        widget.onBoardModified();
      }

      _lastTouchedPoint = pt;
      setState(() {
        _activeRow = pt!.row;
        _activeCol = pt.col;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartPoint = null;
    _lastTouchedPoint = null;
    _dragLock = DragAxisLock.none;
    _visitedInDrag.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _BoardMetrics();
        _calculateMetrics(constraints, metrics);

        final boardTotalWidth = metrics.clueAreaWidth + widget.engine.width * metrics.cellSize;
        final boardTotalHeight = metrics.clueAreaHeight + widget.engine.height * metrics.cellSize;

        final isLargeGrid = widget.engine.width >= 15 || widget.engine.height >= 15;

        Widget boardContent = SizedBox(
          width: boardTotalWidth,
          height: boardTotalHeight,
          child: GestureDetector(
            onPanStart: (d) => _onPanStart(d, metrics.cellSize, metrics.clueAreaWidth, metrics.clueAreaHeight),
            onPanUpdate: (d) => _onPanUpdate(d, metrics.cellSize, metrics.clueAreaWidth, metrics.clueAreaHeight),
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              size: Size(boardTotalWidth, boardTotalHeight),
              painter: PuzzleBoardPainter(
                engine: widget.engine,
                colors: widget.colors,
                activeRow: _activeRow,
                activeCol: _activeCol,
                cellSize: metrics.cellSize,
                clueAreaWidth: metrics.clueAreaWidth,
                clueAreaHeight: metrics.clueAreaHeight,
                isCompleted: widget.engine.isCompleted,
              ),
            ),
          ),
        );

        if (isLargeGrid) {
          // Wrap in smooth InteractiveViewer for 15x15 grids
          return Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.8,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(40),
              panEnabled: false, // keep false so drag gestures draw cells without pan conflict!
              scaleEnabled: true,
              child: boardContent,
            ),
          );
        }

        return Center(child: boardContent);
      },
    );
  }
}

class _BoardMetrics {
  double cellSize = 30;
  double clueAreaWidth = 60;
  double clueAreaHeight = 60;
}
