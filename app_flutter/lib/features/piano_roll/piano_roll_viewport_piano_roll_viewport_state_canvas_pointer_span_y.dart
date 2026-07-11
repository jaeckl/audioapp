part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateCanvaspointerspany on PianoRollViewportState {
  double _canvasPointerSpanY() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.length < 2) return 0;
    return (points[0].dy - points[1].dy).abs();
  }
}
