part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOnpanupdate on _CurveEditorScreenState {
  void _onPanUpdate(DragUpdateDetails details, Size cs) {
    if (_paintShape != null && _shapeStart != null) {
      _updateShapePaint(details.localPosition, cs);
      return;
    }
    switch (_tool) {
      case CurveEditorTool.select:
        _onSelectDrag(details, cs);
      case CurveEditorTool.draw:
        _onDrawUpdate(details, cs);
      case CurveEditorTool.erase:
        break;
    }
  }
}
