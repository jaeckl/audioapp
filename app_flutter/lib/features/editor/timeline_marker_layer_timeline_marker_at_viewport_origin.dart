part of 'timeline_marker_layer.dart';

bool timelineMarkerAtViewportOrigin({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineNaturalViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ).abs() <
      0.5;
}
