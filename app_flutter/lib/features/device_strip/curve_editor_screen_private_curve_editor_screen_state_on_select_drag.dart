part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOnselectdrag on _CurveEditorScreenState {
  void _onSelectDrag(DragUpdateDetails details, Size cs) {
    if (_draggingIndex == null) return;
    final i = _draggingIndex!;
    setState(() {
      final dv = -2.0 * details.delta.dy / cs.height;
      if (i == 0) {
        _positions[i] = 0.0;
        _values[i] = _valueClamp(_values[i] + dv);
      } else if (i == _lastIdx) {
        _positions[i] = 1.0;
        _values[i] = _valueClamp(_values[i] + dv);
      } else {
        final dp = details.delta.dx / cs.width;
        _positions[i] = (_positions[i] + dp).clamp(
          _positions[i - 1] + 0.01,
          _positions[i + 1] - 0.01,
        );
        _values[i] = _valueClamp(_values[i] + dv);
      }
    });
  }
}
