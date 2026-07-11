part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOndrawstart on _CurveEditorScreenState {
  void _onDrawStart(DragStartDetails details, Size cs) {
    final nx = _nx(details.localPosition, cs);
    _drawAccPos.clear();
    _drawAccVal.clear();
    _drawAccPos.add(nx);
    _drawAccVal.add(_ny(details.localPosition, cs));
    setState(() => _selectedIndices.clear());
  }
}
