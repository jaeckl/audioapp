part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateEmitcenteroctave on PianoRollViewportState {
  void _emitCenterOctave() {
    if (widget.onCenterOctaveChanged == null || _lastViewportHeight <= 0) {
      return;
    }
    if (!_vertical.hasClients) return;
    final centerY = _vertical.offset + _lastViewportHeight / 2;
    final pitch = _pitchFromDy(centerY);
    widget.onCenterOctaveChanged!(
      PianoRollMetrics.octaveOffsetFromPitch(pitch),
    );
  }
}
