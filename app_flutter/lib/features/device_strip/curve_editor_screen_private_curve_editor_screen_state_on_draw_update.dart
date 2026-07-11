part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOndrawupdate on _CurveEditorScreenState {
  void _onDrawUpdate(DragUpdateDetails details, Size cs) {
    final nx = _nx(details.localPosition, cs);
    if ((nx - _drawAccPos.last).abs() < 0.015) return;
    _drawAccPos.add(nx);
    _drawAccVal.add(_ny(details.localPosition, cs));
    setState(() => _rebuildFromDraw());
  }
}
