part of 'timeline_marker_layer.dart';

double timelineBeatViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return beat * pixelsPerBeat - scrollOffset;
}
