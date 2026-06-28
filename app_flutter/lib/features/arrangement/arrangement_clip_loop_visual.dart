import 'dart:math' as math;
import 'dart:ui';

import 'arrangement_clip_beat_layout.dart';
import 'arrangement_clip_theme.dart';

/// Shared loop-repeat shading for arrangement clip previews.
class ArrangementClipLoopVisual {
  ArrangementClipLoopVisual._();

  static void paintRepeatRegions({
    required Canvas canvas,
    required Rect contentRect,
    required double contentLengthBeats,
    required double clipLengthBeats,
    required double lengthBeats,
  }) {
    if (contentLengthBeats <= 0 || clipLengthBeats <= contentLengthBeats) {
      return;
    }

    final overlay = Paint()..color = ArrangementClipTheme.loopRepeatOverlay;
    for (var beat = contentLengthBeats;
        beat < clipLengthBeats;
        beat += contentLengthBeats) {
      final left = ArrangementClipBeatLayout.beatToX(
        beat: beat,
        contentRect: contentRect,
        lengthBeats: lengthBeats,
      );
      final right = ArrangementClipBeatLayout.beatToX(
        beat: math.min(beat + contentLengthBeats, clipLengthBeats),
        contentRect: contentRect,
        lengthBeats: lengthBeats,
      );
      if (right <= left) continue;
      canvas.drawRect(
        Rect.fromLTRB(left, contentRect.top, right, contentRect.bottom),
        overlay,
      );
    }
  }
}
