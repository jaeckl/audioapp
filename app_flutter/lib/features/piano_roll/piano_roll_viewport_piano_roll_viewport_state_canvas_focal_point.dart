part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateCanvasfocalpoint on PianoRollViewportState {
  Offset _canvasFocalPoint() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.isEmpty) return Offset.zero;
    var sum = Offset.zero;
    for (final p in points) {
      sum += p;
    }
    return sum / points.length.toDouble();
  }
}
