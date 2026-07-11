part of 'timeline_marker_layer.dart';

double timelineLocalBeatLineLeft({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required double lineWidth,
}) {
  return timelineBeatViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ) -
      lineWidth / 2;
}
