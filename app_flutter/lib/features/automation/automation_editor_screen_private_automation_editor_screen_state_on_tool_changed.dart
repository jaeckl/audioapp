part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateOntoolchanged
    on _AutomationEditorScreenState {
  void _onToolChanged(AutomationEditorTool tool) {
    setState(() {
      _tool = tool;
      _activeShape = null;
      _selectedIndices.clear();
      _deleteMarkedIndices.clear();
      if (tool != AutomationEditorTool.select) {
        _closeInsertPanel(notify: false);
      }
    });
  }
}
