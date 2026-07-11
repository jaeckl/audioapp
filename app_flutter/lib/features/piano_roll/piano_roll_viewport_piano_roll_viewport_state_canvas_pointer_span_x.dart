part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateCanvaspointerspanx on PianoRollViewportState {
  double _canvasPointerSpanX() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.length < 2) return 0;
    return (points[0].dx - points[1].dx).abs();
  }
}
