part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOnpanend on _CurveEditorScreenState {
  void _onPanEnd(DragEndDetails details) {
    if (_paintShape != null && _shapeStart != null) {
      _endShapePaint();
      return;
    }
    switch (_tool) {
      case CurveEditorTool.select:
        if (_draggingIndex != null) {
          _draggingIndex = null;
          _mergeSort();
          _syncToBridge();
        }
      case CurveEditorTool.draw:
        _onDrawEnd();
      case CurveEditorTool.erase:
        break;
    }
  }
}
