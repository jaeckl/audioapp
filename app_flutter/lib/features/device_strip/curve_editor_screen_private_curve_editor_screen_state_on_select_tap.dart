part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateOnselecttap on _CurveEditorScreenState {
  void _onSelectTap(TapUpDetails details, Size cs) {
    final hit = _hitTestPoint(details.localPosition, cs);
    if (hit != null) {
      _toggleSelect(hit);
    } else {
      _clearSelection();
    }
  }
}
