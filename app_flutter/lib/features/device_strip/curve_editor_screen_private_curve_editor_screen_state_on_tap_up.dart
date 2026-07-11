part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOntapup on _CurveEditorScreenState {
  void _onTapUp(TapUpDetails details, Size cs) {
    if (_paintShape != null) return;
    switch (_tool) {
      case CurveEditorTool.select:
        _onSelectTap(details, cs);
      case CurveEditorTool.draw:
        break; // tap in draw mode does nothing
      case CurveEditorTool.erase:
        _onEraseTap(details, cs);
    }
  }
}
