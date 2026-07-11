part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStatePushundo on _AutomationEditorScreenState {
  void _pushUndo() {
    _undoStack.add(_clonePoints(_points));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }
}
