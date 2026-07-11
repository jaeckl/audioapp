part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateSortedpoints
    on AutomationEditorViewportState {
  List<AutomationPointSnapshot> _sortedPoints(
      List<AutomationPointSnapshot> points) {
    return List<AutomationPointSnapshot>.of(points)
      ..sort((a, b) => a.beat.compareTo(b.beat));
  }
}
