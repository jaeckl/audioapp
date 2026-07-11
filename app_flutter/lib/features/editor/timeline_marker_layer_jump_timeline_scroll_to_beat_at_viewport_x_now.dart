part of 'timeline_marker_layer.dart';

bool jumpTimelineScrollToBeatAtViewportXNow({
  required ScrollController horizontal,
  required double beat,
  required double pixelsPerBeat,
  required double viewportX,
  ScrollController? ruler,
  ScrollController? mirror,
}) {
  if (!horizontal.hasClients) {
    return false;
  }
  final target = timelineScrollOffsetForBeatAtViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    viewportX: viewportX,
  ).clamp(0.0, horizontal.position.maxScrollExtent);
  horizontal.jumpTo(target);
  if (ruler != null && ruler.hasClients) {
    ruler.jumpTo(target.clamp(0.0, ruler.position.maxScrollExtent));
  }
  if (mirror != null && mirror.hasClients) {
    mirror.jumpTo(target.clamp(0.0, mirror.position.maxScrollExtent));
  }
  return true;
}
