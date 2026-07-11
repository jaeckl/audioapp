part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOnerasetap on _CurveEditorScreenState {
  void _onEraseTap(TapUpDetails details, Size cs) {
    if (_bpCount <= 2) return;
    final hit = _hitTestPoint(details.localPosition, cs);
    if (hit == null || hit == 0 || hit == _lastIdx) return;
    setState(() {
      _positions.removeAt(hit);
      _values.removeAt(hit);
      _shapes.removeAt(hit);
      _mergeSort();
      _bpCount = _positions.length;
      _selectedIndices.clear();
    });
    _syncToBridge();
  }
}
