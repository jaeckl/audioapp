part of 'timeline_marker_layer.dart';

double timelineScrollOffsetForBeatAtViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double viewportX,
}) {
  return beat * pixelsPerBeat - viewportX;
}
