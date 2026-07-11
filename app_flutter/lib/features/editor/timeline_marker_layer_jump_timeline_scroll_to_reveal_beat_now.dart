part of 'timeline_marker_layer.dart';

bool jumpTimelineScrollToRevealBeatNow({
  required ScrollController horizontal,
  required double beat,
  required double pixelsPerBeat,
  ScrollController? ruler,
  ScrollController? mirror,
}) {
  return jumpTimelineScrollToBeatAtViewportXNow(
    horizontal: horizontal,
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    viewportX: 0,
    ruler: ruler,
    mirror: mirror,
  );
}
