part of 'timeline_marker_layer.dart';

void jumpTimelineScrollToRevealBeat({
  required ScrollController horizontal,
  required double beat,
  required double pixelsPerBeat,
  ScrollController? ruler,
  ScrollController? mirror,
  VoidCallback? onComplete,
  int attempt = 0,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!horizontal.hasClients) {
      if (attempt < 12) {
        jumpTimelineScrollToRevealBeat(
          horizontal: horizontal,
          beat: beat,
          pixelsPerBeat: pixelsPerBeat,
          ruler: ruler,
          mirror: mirror,
          onComplete: onComplete,
          attempt: attempt + 1,
        );
      }
      return;
    }
    jumpTimelineScrollToRevealBeatNow(
      horizontal: horizontal,
      beat: beat,
      pixelsPerBeat: pixelsPerBeat,
      ruler: ruler,
      mirror: mirror,
    );
    onComplete?.call();
  });
}
