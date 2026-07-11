part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateClampcliplength
    on AutomationEditorViewportState {
  double _clampClipLength(double beats) {
    final minLen = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : kMinClipLengthBeats;
    final clamped = beats.clamp(minLen, widget.virtualLengthBeats);
    return widget.gridSettings.snapBeat(clamped);
  }
}
