part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateCleartransientselection
    on _AutomationEditorScreenState {
  void _clearTransientSelection() {
    _selectedIndices.clear();
    _deleteMarkedIndices.clear();
  }
}
