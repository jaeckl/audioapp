part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateEndshapepaint on _CurveEditorScreenState {
  void _endShapePaint() {
    _shapeSourcePositions = null;
    _shapeSourceValues = null;
    _shapeSourceKinds = null;
    _shapeStart = null;
    _shapeEnd = null;
    _shapeBaseline = null;
    _mergeSort();
    _bpCount = _positions.length;
    _syncToBridge();
    setState(() {});
  }
}
