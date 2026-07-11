part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateToggledeletemark
    on _AutomationEditorScreenState {
  void _toggleDeleteMark(int index) {
    setState(() {
      if (_deleteMarkedIndices.contains(index)) {
        _deleteMarkedIndices.remove(index);
      } else {
        _deleteMarkedIndices.add(index);
      }
    });
  }
}
