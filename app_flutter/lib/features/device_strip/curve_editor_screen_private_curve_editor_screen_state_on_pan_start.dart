part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOnpanstart on _CurveEditorScreenState {
  void _onPanStart(DragStartDetails details, Size cs) {
    if (_paintShape != null) {
      _startShapePaint(details.localPosition, cs);
      return;
    }
    switch (_tool) {
      case CurveEditorTool.select:
        setState(() {
          _draggingIndex = _hitTestPoint(details.localPosition, cs);
        });
      case CurveEditorTool.draw:
        _onDrawStart(details, cs);
      case CurveEditorTool.erase:
        break;
    }
  }
}
