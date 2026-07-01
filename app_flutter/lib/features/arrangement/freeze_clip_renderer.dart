import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'arrangement_clip_beat_layout.dart';
import 'arrangement_clip_theme.dart';
import 'clip_renderer.dart';

/// Full-track frozen audio clip — waveform from baked pre-gain render peaks.
class FreezeClipRenderer extends ClipRenderer {
  const FreezeClipRenderer(this.freeze);

  final TrackFreezeSnapshot freeze;

  @override
  Color get clipBackgroundColor => ArrangementClipTheme.freezeClipBackground;

  @override
  Color get clipContentBackgroundColor =>
      ArrangementClipTheme.contentBackground(clipBackgroundColor);

  @override
  bool get loopContentEnabled => false;

  @override
  String? get headerLabel => freeze.stale ? 'Frozen (stale)' : 'Frozen';

  @override
  void paintContent(Canvas canvas, Rect contentRect) {
    final peaks = freeze.waveformPeaks;
    if (peaks.isEmpty || contentRect.width <= 0 || contentRect.height <= 0) {
      return;
    }

    final pixelsPerBeat = ArrangementClipBeatLayout.pixelsPerBeat(
      contentRect: contentRect,
      lengthBeats: freeze.lengthBeats,
    );
    final naturalPx = freeze.lengthBeats * pixelsPerBeat;
    final step = naturalPx / peaks.length;

    final paint = Paint()
      ..color = freeze.stale
          ? ArrangementClipTheme.freezeWaveform.withValues(alpha: 0.45)
          : ArrangementClipTheme.freezeWaveform
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final midY = contentRect.center.dy;
    final halfHeight = contentRect.height / 2;
    final left = contentRect.left;

    for (var i = 0; i < peaks.length; i++) {
      final peak = peaks[i].clamp(0.0, 1.0);
      final x = left + i * step + step / 2;
      if (x > contentRect.right) break;
      final half = peak * halfHeight;
      canvas.drawLine(
        Offset(x, midY - half),
        Offset(x, midY + half),
        paint,
      );
    }
  }
}
