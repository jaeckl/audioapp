part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateResettodefault on _CurveEditorScreenState {
  void _resetToDefault() {
    setState(() {
      _positions = [0.0, 1.0];
      _values = [_polarity == 0 ? 0.0 : 0.5, _polarity == 0 ? 1.0 : 0.5];
      _shapes = [0, 0];
      _bpCount = 2;
      _selectedIndices.clear();
    });
    _syncToBridge();
  }
}
