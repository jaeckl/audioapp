part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateBeatfromdx
    on AutomationEditorViewportState {
  double _beatFromDx(double dx, {bool snap = true}) {
    final beat = AutomationEditorMetrics.beatFromDx(dx, _pixelsPerBeat)
        .clamp(0.0, widget.virtualLengthBeats);
    return snap ? widget.gridSettings.snapBeat(beat) : beat;
  }
}
