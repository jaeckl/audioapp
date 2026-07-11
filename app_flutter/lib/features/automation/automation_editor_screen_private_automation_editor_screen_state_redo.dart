part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateRedo on _AutomationEditorScreenState {
  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_clonePoints(_points));
    setState(() {
      _points = _redoStack.removeLast();
      _clearTransientSelection();
    });
    _persistPoints();
  }
}
