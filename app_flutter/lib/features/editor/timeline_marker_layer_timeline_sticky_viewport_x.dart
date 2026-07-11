part of 'timeline_marker_layer.dart';

double timelineStickyViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  final natural = timelineNaturalViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  return natural < 0 ? 0.0 : natural;
}
