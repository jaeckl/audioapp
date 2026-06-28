import 'dart:ui';

import 'clip_renderer.dart';

/// Maps clip-local beats to arrangement grid pixels inside clip chrome.
class ArrangementClipBeatLayout {
  ArrangementClipBeatLayout._();

  static double pixelsPerBeat({
    required Rect contentRect,
    required double lengthBeats,
  }) {
    if (lengthBeats <= 0) {
      return 0;
    }
    final clipWidthPx = contentRect.width + 2 * ArrangementClipChrome.contentInset;
    return clipWidthPx / lengthBeats;
  }

  /// X in [CustomPaint] coords for [beat] inside a clip block.
  static double beatToX({
    required double beat,
    required Rect contentRect,
    required double lengthBeats,
  }) {
    return beat * pixelsPerBeat(contentRect: contentRect, lengthBeats: lengthBeats) -
        ArrangementClipChrome.contentInset;
  }
}
