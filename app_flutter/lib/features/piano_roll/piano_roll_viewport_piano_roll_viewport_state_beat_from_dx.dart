part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBeatfromdx on PianoRollViewportState {
  double _beatFromDx(double dx, {bool snap = true}) {
    final beat = (dx / _pixelsPerBeat).clamp(0.0, widget.virtualLengthBeats);
    return snap ? widget.gridSettings.snapBeat(beat) : beat;
  }
}
