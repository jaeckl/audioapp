part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateHittestpoint on _CurveEditorScreenState {
  int? _hitTestPoint(Offset localPos, Size s) {
    for (var i = 0; i < _bpCount; i++) {
      final x = _positions[i] * s.width;
      final y = s.height * (0.5 - _values[i] * 0.5);
      if ((localPos - Offset(x, y)).distance <= _hitRadius) return i;
    }
    return null;
  }
}
