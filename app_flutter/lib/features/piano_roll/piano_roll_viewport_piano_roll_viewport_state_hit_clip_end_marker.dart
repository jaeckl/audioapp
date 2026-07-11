part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateHitclipendmarker on PianoRollViewportState {
  bool _hitClipEndMarker(Offset canvasPos) {
    final endX = widget.clipLengthBeats * _pixelsPerBeat;
    return (canvasPos.dx - endX).abs() <= PianoRollMetrics.clipEndHitWidth / 2;
  }
}
