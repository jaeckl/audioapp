part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateClonepoints
    on _AutomationEditorScreenState {
  List<AutomationPointSnapshot> _clonePoints(
      List<AutomationPointSnapshot> points) {
    return points
        .map((p) => AutomationPointSnapshot(beat: p.beat, value: p.value))
        .toList();
  }
}
