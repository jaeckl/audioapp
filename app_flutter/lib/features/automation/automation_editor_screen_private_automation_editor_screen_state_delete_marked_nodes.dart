part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateDeletemarkednodes
    on _AutomationEditorScreenState {
  void _deleteMarkedNodes() {
    if (_deleteMarkedIndices.isEmpty) return;
    if (_points.length - _deleteMarkedIndices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Automation needs at least two points'),
          backgroundColor: AutomationEditorTheme.saveError,
        ),
      );
      return;
    }
    _pushUndo();
    setState(() {
      _points = [
        for (var i = 0; i < _points.length; i++)
          if (!_deleteMarkedIndices.contains(i)) _points[i],
      ];
      _deleteMarkedIndices.clear();
    });
    _persistPoints();
  }
}
