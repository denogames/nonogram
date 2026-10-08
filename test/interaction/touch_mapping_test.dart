import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram/engine/models/grid_point.dart';

void main() {
  group('Touch-to-cell and Coordinate Mapping tests', () {
    const double clueAreaWidth = 60.0;
    const double clueAreaHeight = 60.0;
    const double cellSize = 30.0;
    const int gridWidth = 10;
    const int gridHeight = 10;

    GridPoint? pointFromOffset(double x, double y) {
      final localX = x - clueAreaWidth;
      final localY = y - clueAreaHeight;

      if (localX < 0 || localY < 0) return null;

      final col = (localX / cellSize).floor();
      final row = (localY / cellSize).floor();

      if (row >= 0 && row < gridHeight && col >= 0 && col < gridWidth) {
        return GridPoint(row, col);
      }
      return null;
    }

    test('Coordinates within clue areas return null', () {
      // Tap in top-left clue intersection
      expect(pointFromOffset(20.0, 20.0), isNull);
      // Tap in row clue area (left side)
      expect(pointFromOffset(15.0, 75.0), isNull);
      // Tap in column clue area (top side)
      expect(pointFromOffset(75.0, 15.0), isNull);
    });

    test('Coordinates inside grid map to exact cell (0, 0)', () {
      // (60, 60) is top-left corner of cell (0, 0)
      final pt = pointFromOffset(65.0, 65.0);
      expect(pt, isNotNull);
      expect(pt!.row, 0);
      expect(pt.col, 0);
    });

    test('Coordinates map accurately to interior cells', () {
      // Cell (3, 4) starts at x = 60 + 4*30 = 180, y = 60 + 3*30 = 150
      final pt = pointFromOffset(185.0, 160.0);
      expect(pt, isNotNull);
      expect(pt!.row, 3);
      expect(pt.col, 4);
    });

    test('Coordinates outside grid boundary return null', () {
      // Beyond right edge (x >= 60 + 10*30 = 360)
      expect(pointFromOffset(365.0, 100.0), isNull);
      // Beyond bottom edge (y >= 60 + 10*30 = 360)
      expect(pointFromOffset(100.0, 370.0), isNull);
    });

    test('Zoom scale factor transforms coordinates linearly', () {
      const zoomScale = 1.5;
      final zoomedCellSize = cellSize * zoomScale; // 45.0
      final zoomedClueW = clueAreaWidth * zoomScale; // 90.0
      final zoomedClueH = clueAreaHeight * zoomScale; // 90.0

      GridPoint? zoomedPointFromOffset(double x, double y) {
        final localX = x - zoomedClueW;
        final localY = y - zoomedClueH;
        if (localX < 0 || localY < 0) return null;
        final col = (localX / zoomedCellSize).floor();
        final row = (localY / zoomedCellSize).floor();
        if (row >= 0 && row < gridHeight && col >= 0 && col < gridWidth) {
          return GridPoint(row, col);
        }
        return null;
      }

      // Point (2, 2): x = 90 + 2*45 + 10 = 190, y = 90 + 2*45 + 10 = 190
      final pt = zoomedPointFromOffset(190.0, 190.0);
      expect(pt, isNotNull);
      expect(pt!.row, 2);
      expect(pt.col, 2);
    });
  });
}
