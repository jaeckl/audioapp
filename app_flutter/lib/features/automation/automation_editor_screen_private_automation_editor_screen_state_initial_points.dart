part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateInitialpoints
    on _AutomationEditorScreenState {
  List<AutomationPointSnapshot> _initialPoints(AutomationClipSnapshot clip) {
    final points = List<AutomationPointSnapshot>.of(clip.points);
    if (points.length < 2) {
      return [
        const AutomationPointSnapshot(beat: 0, value: 1),
        AutomationPointSnapshot(
            beat: clip.editorContentLengthBeats, value: 0.25),
      ];
    }
    return points;
  }
}
