part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateClearselection on _CurveEditorScreenState {
  void _clearSelection() {
    setState(() => _selectedIndices.clear());
  }
}
