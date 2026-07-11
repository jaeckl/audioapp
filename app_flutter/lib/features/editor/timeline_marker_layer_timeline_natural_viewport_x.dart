part of 'timeline_marker_layer.dart';

double timelineNaturalViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineBeatViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
}
