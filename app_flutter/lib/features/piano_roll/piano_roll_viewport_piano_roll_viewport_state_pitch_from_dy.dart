part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStatePitchfromdy on PianoRollViewportState {
  int _pitchFromDy(double dy) {
    if (widget.laneLayout != null) {
      final pitches = _visiblePitches;
      final row = (dy / _rowHeight).floor().clamp(0, pitches.length - 1);
      return pitches[row];
    }
    final pitch = widget.maxPitch - (dy / _rowHeight).floor();
    return widget.scaleSettings.snapPitch(
      pitch,
      minPitch: widget.minPitch,
      maxPitch: widget.maxPitch,
    );
  }
}
