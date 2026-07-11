part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateUndo on _AutomationEditorScreenState {
  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_clonePoints(_points));
    setState(() {
      _points = _undoStack.removeLast();
      _clearTransientSelection();
    });
    _persistPoints();
  }
}
