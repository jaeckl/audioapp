part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateSelectshapetool
    on _AutomationEditorScreenState {
  void _selectShapeTool(AutomationCurveShape shape) {
    _closeInsertPanel(notify: false);
    setState(() {
      _tool = AutomationEditorTool.select;
      _activeShape = shape;
      _selectedIndices.clear();
      _deleteMarkedIndices.clear();
    });
  }
}
