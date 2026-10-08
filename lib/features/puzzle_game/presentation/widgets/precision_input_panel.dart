import 'package:flutter/material.dart';
import '../../../../core/audio/haptics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../engine/game/puzzle_engine.dart';
import '../../../../engine/models/cell_state.dart';

class PrecisionInputPanel extends StatefulWidget {
  final PuzzleEngine engine;
  final PuzzleColors colors;
  final EditTool currentTool;
  final VoidCallback onModified;

  const PrecisionInputPanel({
    super.key,
    required this.engine,
    required this.colors,
    required this.currentTool,
    required this.onModified,
  });

  @override
  State<PrecisionInputPanel> createState() => _PrecisionInputPanelState();
}

class _PrecisionInputPanelState extends State<PrecisionInputPanel> {
  int _selectedRow = 0;
  bool _isRowMode = true; // true = Row mode, false = Column mode

  @override
  Widget build(BuildContext context) {
    final maxIndex = _isRowMode ? widget.engine.height : widget.engine.width;
    final length = _isRowMode ? widget.engine.width : widget.engine.height;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        border: Border(top: BorderSide(color: widget.colors.gridBorder.withOpacity(0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row / Column Selector Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isRowMode = !_isRowMode;
                    _selectedRow = 0;
                  });
                },
                icon: Icon(_isRowMode ? Icons.table_rows_rounded : Icons.view_column_rounded),
                label: Text(
                  _isRowMode ? 'Row ${_selectedRow + 1}' : 'Column ${_selectedRow + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _selectedRow > 0
                        ? () {
                            HapticsService.selectionClick();
                            setState(() => _selectedRow--);
                          }
                        : null,
                  ),
                  Text('${_selectedRow + 1} / $maxIndex'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _selectedRow < maxIndex - 1
                        ? () {
                            HapticsService.selectionClick();
                            setState(() => _selectedRow++);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),

          // Enlarged Cells Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(length, (index) {
                final r = _isRowMode ? _selectedRow : index;
                final c = _isRowMode ? index : _selectedRow;
                final state = widget.engine.getCell(r, c);

                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: InkWell(
                    onTap: () {
                      HapticsService.lightImpact();
                      widget.engine.applyTool(r, c, widget.currentTool);
                      widget.onModified();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: state == CellState.filled
                            ? widget.colors.cellFilled
                            : widget.colors.cellEmpty,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.colors.gridBorder.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: state == CellState.crossed
                            ? Icon(Icons.close_rounded, color: widget.colors.cellCrossed, size: 28)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: state == CellState.filled
                                      ? Colors.white
                                      : widget.colors.textSecondary.withOpacity(0.5),
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
