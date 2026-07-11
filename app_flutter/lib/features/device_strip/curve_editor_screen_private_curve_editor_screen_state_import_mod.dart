part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateImportmod on _CurveEditorScreenState {
  void _importMod() {
    _positions = List<double>.from(widget.mod.curveBpPositions);
    _values = List<double>.from(widget.mod.curveBpValues);
    _shapes = List<int>.from(widget.mod.curveBpShapes);
    _mergeSort();
    _bpCount = _positions.length;
    _polarity = widget.mod.polarity;
    _selectedIndices.clear();
  }
}
