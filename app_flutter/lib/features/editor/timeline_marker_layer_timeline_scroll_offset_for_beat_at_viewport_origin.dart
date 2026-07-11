part of 'timeline_marker_layer.dart';

double timelineScrollOffsetForBeatAtViewportOrigin({
  required double beat,
  required double pixelsPerBeat,
}) {
  return timelineScrollOffsetForBeatAtViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    viewportX: 0,
  );
}
