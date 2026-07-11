part of 'timeline_marker_layer.dart';

Future<void> animateTimelineScrollToBeatAtViewportX({
  required ScrollController horizontal,
  required double beat,
  required double pixelsPerBeat,
  required double viewportX,
  Duration duration = const Duration(milliseconds: 120),
  Curve curve = Curves.easeOut,
}) async {
  if (!horizontal.hasClients) {
    return;
  }
  final target = timelineScrollOffsetForBeatAtViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    viewportX: viewportX,
  ).clamp(0.0, horizontal.position.maxScrollExtent);
  await horizontal.animateTo(target, duration: duration, curve: curve);
}
