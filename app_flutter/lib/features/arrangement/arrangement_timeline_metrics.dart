// Timeline zoom and clip layout helpers for the arrangement view.
import 'dart:math' as math;

class ArrangementTimelineMetrics {
  static const double defaultPixelsPerBeat = 64;
  static const double minPixelsPerBeat = 28;
  static const double maxPixelsPerBeat = 200;
  static const double trackHeaderWidth = 44;
  static const double trackLaneHeight = 56;
  static const double timelineBeats = 32;
  static const double minClipDisplayWidthPx = 120;

  static double clampPixelsPerBeat(double value) {
    return value.clamp(minPixelsPerBeat, maxPixelsPerBeat);
  }

  /// Readable floor scales with zoom so pinch in/out changes clip width visibly.
  static double scaledMinClipWidthPx(double pixelsPerBeat) {
    return minClipDisplayWidthPx * (pixelsPerBeat / defaultPixelsPerBeat);
  }

  /// Visual clip width: beat-accurate length × zoom, with a zoom-scaled readable floor.
  static double clipDisplayWidthPx({
    required double startBeat,
    required double lengthBeats,
    required double pixelsPerBeat,
    required double gapEndBeat,
    double? viewportWidthPx,
  }) {
    final minWidthPx = scaledMinClipWidthPx(pixelsPerBeat);
    final startPx = startBeat * pixelsPerBeat;
    final naturalPx = lengthBeats * pixelsPerBeat;
    final gapEndPx = gapEndBeat * pixelsPerBeat;
    final availablePx = (gapEndPx - startPx).clamp(0.0, double.infinity);
    if (availablePx <= 0) {
      return naturalPx > 0 ? naturalPx : minWidthPx;
    }

    var width = math.max(naturalPx, minWidthPx);
    width = width.clamp(minWidthPx, availablePx);

    // At default zoom only: lone short clips may grow into empty lane space.
    if (pixelsPerBeat <= defaultPixelsPerBeat + 0.5 &&
        viewportWidthPx != null &&
        viewportWidthPx > minWidthPx &&
        naturalPx < viewportWidthPx * 0.35) {
      width = width.clamp(minWidthPx, math.max(width, math.min(availablePx, viewportWidthPx)));
    }

    return width;
  }

  static double gapEndBeatForClip({
    required double clipStartBeat,
    required List<double> otherClipStarts,
    required double timelineEndBeat,
  }) {
    var gapEnd = timelineEndBeat;
    for (final start in otherClipStarts) {
      if (start > clipStartBeat && start < gapEnd) {
        gapEnd = start;
      }
    }
    return gapEnd;
  }
}
