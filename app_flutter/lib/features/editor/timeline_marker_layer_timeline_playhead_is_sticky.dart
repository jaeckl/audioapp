part of 'timeline_marker_layer.dart';

bool timelinePlayheadIsSticky({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineNaturalViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ) <
      0;
}
