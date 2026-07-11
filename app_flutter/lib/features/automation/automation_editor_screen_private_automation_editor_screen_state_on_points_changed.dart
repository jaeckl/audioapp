part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateOnpointschanged
    on _AutomationEditorScreenState {
  void _onPointsChanged(List<AutomationPointSnapshot> points) {
    setState(() => _points = points);
  }
}
