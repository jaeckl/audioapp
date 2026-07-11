part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOndrawend on _CurveEditorScreenState {
  void _onDrawEnd() {
    _rebuildFromDraw();
    _drawAccPos.clear();
    _drawAccVal.clear();
    _syncToBridge();
  }
}
