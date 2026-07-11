part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateClampcliplength on PianoRollViewportState {
  double _clampClipLength(double beats) {
    final minLen = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : kMinClipLengthBeats;
    return beats.clamp(minLen, widget.virtualLengthBeats);
  }
}
