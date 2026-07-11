part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOpenshapesheet on _CurveEditorScreenState {
  void _openShapeSheet() {
    if (_selectedIndices.length != 2) return;

    final sorted = _selectedIndices
        .map((i) => (idx: i, pos: _positions[i], val: _values[i]))
        .toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));

    final startPos = sorted[0].pos;
    final endPos = sorted[1].pos;
    final startVal = sorted[0].val;
    final endVal = sorted[1].val;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return _ShapeInsertSheet(
          accent: _accent,
          polarity: _polarity,
          startVal: startVal,
          endVal: endVal,
          onApply: (shapeName, floor, peak, cycles) {
            _insertShapeBetween(shapeName, startPos, endPos, startVal, endVal,
                floor: floor, peak: peak, cycles: cycles);
          },
        );
      },
    );
  }
}
