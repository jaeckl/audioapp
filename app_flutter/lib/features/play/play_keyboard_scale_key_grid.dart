part of 'play_keyboard.dart';

class _ScaleKeyGrid extends StatelessWidget {
  const _ScaleKeyGrid({
    required this.pitches,
    required this.scale,
    required this.rows,
    required this.scrollOffset,
    required this.held,
    required this.highlighted,
    required this.onDown,
    required this.onUp,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  final List<int> pitches;
  final PlayScale scale;
  final int rows;
  final int scrollOffset;
  final Set<int> held;
  final Set<int> highlighted;
  final Future<void> Function(int pitch, double y, double h) onDown;
  final Future<void> Function(int pitch) onUp;
  final void Function(int pitch, int pointer, Offset local) onPointerDown;
  final void Function(int pointer, Offset local, Size keySize) onPointerMove;
  final Future<void> Function(int pointer) onPointerEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PlayDeckTheme.cellGap;
        final rowH = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final cols = _columnCount(constraints.maxWidth, rowH, gap);
        final pageSize = cols * rows;
        final start = scrollOffset.clamp(
            0, (pitches.length - pageSize).clamp(0, pitches.length));
        final visible = pitches.sublist(
          start,
          (start + pageSize).clamp(0, pitches.length),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: gap),
              SizedBox(
                height: rowH,
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) SizedBox(width: gap),
                      Expanded(child: _cellAt(visible, start, r, c, cols)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _cellAt(List<int> visible, int start, int row, int col, int cols) {
    final index = row * cols + col;
    if (index >= visible.length) {
      return const SizedBox.shrink();
    }
    final pitch = visible[index];
    final globalIndex = start + index;
    final isRoot =
        scale.id != 'chromatic' && globalIndex % scale.intervals.length == 0;

    return _KeyCell(
      light: scale.id == 'chromatic',
      isRoot: isRoot,
      active: held.contains(pitch) || highlighted.contains(pitch),
      onDown: (y, h) => onDown(pitch, y, h),
      onUp: () => onUp(pitch),
      onPointerDown: (pointer, local) => onPointerDown(pitch, pointer, local),
      onPointerMove: onPointerMove,
      onPointerEnd: onPointerEnd,
    );
  }

  int _columnCount(double width, double rowHeight, double gap) {
    final cellW = rowHeight.clamp(PlayDeckLayout.keyCellMinSize, 80.0);
    final cols = ((width + gap) / (cellW + gap)).floor();
    return cols.clamp(3, PlayDeckLayout.keyMaxColumns);
  }
}
