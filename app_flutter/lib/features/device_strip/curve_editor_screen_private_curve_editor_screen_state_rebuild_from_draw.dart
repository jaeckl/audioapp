part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateRebuildfromdraw on _CurveEditorScreenState {
  void _rebuildFromDraw() {
    if (_drawAccPos.isEmpty) return;
    final drawMin = _drawAccPos.reduce(math.min);
    final drawMax = _drawAccPos.reduce(math.max);

    final newPos = <double>[];
    final newVal = <double>[];
    final newShape = <int>[];

    // Points strictly before draw range (left endpoint only if outside draw).
    for (var i = 0; i < _bpCount; i++) {
      if (_positions[i] < drawMin - 1e-6) {
        newPos.add(_positions[i]);
        newVal.add(_values[i]);
        newShape.add(_shapes[i]);
      }
    }

    // Drawn points.
    for (var i = 0; i < _drawAccPos.length; i++) {
      newPos.add(_drawAccPos[i]);
      newVal.add(_drawAccVal[i]);
      newShape.add(0);
    }

    // Points strictly after draw range (right endpoint only if outside draw).
    for (var i = 0; i < _bpCount; i++) {
      if (_positions[i] > drawMax + 1e-6) {
        newPos.add(_positions[i]);
        newVal.add(_values[i]);
        newShape.add(_shapes[i]);
      }
    }

    _positions = newPos;
    _values = newVal;
    _shapes = newShape;
    _mergeSort();
    _bpCount = _positions.length;
  }
}
