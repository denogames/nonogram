import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../engine/game/puzzle_engine.dart';
import '../../../../engine/models/cell_state.dart';

class PuzzleBoardPainter extends CustomPainter {
  final PuzzleEngine engine;
  final PuzzleColors colors;
  final int? activeRow;
  final int? activeCol;
  final double cellSize;
  final double clueAreaWidth;
  final double clueAreaHeight;
  final bool isCompleted;

  PuzzleBoardPainter({
    required this.engine,
    required this.colors,
    this.activeRow,
    this.activeCol,
    required this.cellSize,
    required this.clueAreaWidth,
    required this.clueAreaHeight,
    this.isCompleted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = engine.width;
    final height = engine.height;

    final gridLeft = clueAreaWidth;
    final gridTop = clueAreaHeight;
    final gridWidth = width * cellSize;
    final gridHeight = height * cellSize;

    // 1. Draw Clue Area Backgrounds
    final clueBgPaint = Paint()..color = colors.clueBackground;
    // Top column clues background
    canvas.drawRect(Rect.fromLTWH(gridLeft, 0, gridWidth, clueAreaHeight), clueBgPaint);
    // Left row clues background
    canvas.drawRect(Rect.fromLTWH(0, gridTop, clueAreaWidth, gridHeight), clueBgPaint);

    // 2. Active Row / Column Highlighting
    if (!isCompleted) {
      final highlightPaint = Paint()..color = colors.cellActiveHighlight;
      if (activeRow != null && activeRow! >= 0 && activeRow! < height) {
        // Highlight row clue
        canvas.drawRect(
          Rect.fromLTWH(0, gridTop + activeRow! * cellSize, clueAreaWidth, cellSize),
          Paint()..color = colors.clueActiveBackground,
        );
        // Highlight row in grid
        canvas.drawRect(
          Rect.fromLTWH(gridLeft, gridTop + activeRow! * cellSize, gridWidth, cellSize),
          highlightPaint,
        );
      }
      if (activeCol != null && activeCol! >= 0 && activeCol! < width) {
        // Highlight col clue
        canvas.drawRect(
          Rect.fromLTWH(gridLeft + activeCol! * cellSize, 0, cellSize, clueAreaHeight),
          Paint()..color = colors.clueActiveBackground,
        );
        // Highlight col in grid
        canvas.drawRect(
          Rect.fromLTWH(gridLeft + activeCol! * cellSize, gridTop, cellSize, gridHeight),
          highlightPaint,
        );
      }
    }

    // 3. Draw Grid Cells
    final filledPaint = Paint()..color = colors.cellFilled;
    final crossPaint = Paint()
      ..color = colors.cellCrossed
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        final state = engine.getCell(r, c);
        final cellRect = Rect.fromLTWH(
          gridLeft + c * cellSize,
          gridTop + r * cellSize,
          cellSize,
          cellSize,
        );

        if (state == CellState.filled) {
          final fillInset = cellSize * 0.08;
          final rrect = RRect.fromRectAndRadius(
            cellRect.deflate(fillInset),
            Radius.circular(cellSize * 0.12),
          );
          canvas.drawRRect(rrect, filledPaint);
        } else if (state == CellState.crossed && !isCompleted) {
          final inset = cellSize * 0.22;
          canvas.drawLine(
            Offset(cellRect.left + inset, cellRect.top + inset),
            Offset(cellRect.right - inset, cellRect.bottom - inset),
            crossPaint,
          );
          canvas.drawLine(
            Offset(cellRect.right - inset, cellRect.top + inset),
            Offset(cellRect.left + inset, cellRect.bottom - inset),
            crossPaint,
          );
        }
      }
    }

    // 4. Draw Grid Lines (Major lines every 5 cells, Minor lines elsewhere)
    final minorLinePaint = Paint()
      ..color = colors.gridMinorLine
      ..strokeWidth = 1.0;
    final majorLinePaint = Paint()
      ..color = colors.gridMajorLine
      ..strokeWidth = 2.0;

    // Horizontal grid lines
    for (int r = 0; r <= height; r++) {
      final y = gridTop + r * cellSize;
      final isMajor = r % 5 == 0;
      canvas.drawLine(
        Offset(gridLeft, y),
        Offset(gridLeft + gridWidth, y),
        isMajor ? majorLinePaint : minorLinePaint,
      );
    }

    // Vertical grid lines
    for (int c = 0; c <= width; c++) {
      final x = gridLeft + c * cellSize;
      final isMajor = c % 5 == 0;
      canvas.drawLine(
        Offset(x, gridTop),
        Offset(x, gridTop + gridHeight),
        isMajor ? majorLinePaint : minorLinePaint,
      );
    }

    // 5. Draw Row Clues
    for (int r = 0; r < height; r++) {
      final clues = engine.puzzle.rowHints[r];
      final isRowDone = engine.isRowCompleted(r);
      final textColor = isRowDone ? colors.clueCompletedText : colors.clueText;
      final textStyle = TextStyle(
        color: textColor,
        fontSize: (cellSize * 0.42).clamp(10.0, 15.0),
        fontWeight: isRowDone ? FontWeight.normal : FontWeight.w700,
        decoration: isRowDone ? TextDecoration.lineThrough : null,
      );

      final clueString = clues.where((n) => n > 0).join('  ');
      final textSpan = TextSpan(text: clueString.isEmpty ? '0' : clueString, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout(maxWidth: clueAreaWidth - 8);
      textPainter.paint(
        canvas,
        Offset(
          clueAreaWidth - textPainter.width - 6,
          gridTop + r * cellSize + (cellSize - textPainter.height) / 2,
        ),
      );
    }

    // 6. Draw Column Clues (stacked vertically inside each column header)
    for (int c = 0; c < width; c++) {
      final clues = engine.puzzle.columnHints[c];
      final isColDone = engine.isColCompleted(c);
      final textColor = isColDone ? colors.clueCompletedText : colors.clueText;
      final textStyle = TextStyle(
        color: textColor,
        fontSize: (cellSize * 0.42).clamp(10.0, 15.0),
        fontWeight: isColDone ? FontWeight.normal : FontWeight.w700,
        decoration: isColDone ? TextDecoration.lineThrough : null,
      );

      final activeNumbers = clues.where((n) => n > 0).toList();
      final numbersToDraw = activeNumbers.isEmpty ? [0] : activeNumbers;

      // Draw numbers stacked from bottom to top
      double currentY = clueAreaHeight - 4;
      for (final n in numbersToDraw.reversed) {
        final tp = TextPainter(
          text: TextSpan(text: '$n', style: textStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        tp.layout();
        currentY -= tp.height;
        tp.paint(
          canvas,
          Offset(
            gridLeft + c * cellSize + (cellSize - tp.width) / 2,
            currentY,
          ),
        );
        currentY -= 2;
      }
    }

    // 7. Outer Border
    final borderPaint = Paint()
      ..color = colors.gridBorder
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(gridLeft, gridTop, gridWidth, gridHeight), borderPaint);
  }

  @override
  bool shouldRepaint(covariant PuzzleBoardPainter oldDelegate) {
    return true;
  }
}
