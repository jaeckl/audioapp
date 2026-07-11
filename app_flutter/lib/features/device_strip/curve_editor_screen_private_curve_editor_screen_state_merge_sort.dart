part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateMergesort on _CurveEditorScreenState {
  void _mergeSort() {
    for (var i = 0; i < _positions.length; i++) {
      for (var j = i + 1; j < _positions.length; j++) {
        if (_positions[j] < _positions[i]) {
          double tmp = _positions[i];
          _positions[i] = _positions[j];
          _positions[j] = tmp;
          tmp = _values[i];
          _values[i] = _values[j];
          _values[j] = tmp;
          final stmp = _shapes[i];
          _shapes[i] = _shapes[j];
          _shapes[j] = stmp;
        }
      }
    }
    // Remove duplicate positions (within epsilon).
    for (var i = _positions.length - 1; i >= 1; i--) {
      if ((_positions[i] - _positions[i - 1]).abs() < 1e-9) {
        _positions.removeAt(i);
        _values.removeAt(i);
        _shapes.removeAt(i);
      }
    }
    _selectedIndices.clear();
  }
}
