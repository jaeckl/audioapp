import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'arrangement_clip_theme.dart';
import 'clip_renderer.dart';

/// Waveform preview for arrangement audio/sample clips.
class SampleClipRenderer extends ClipRenderer {
  const SampleClipRenderer(this.clip);

  final SampleClipSnapshot clip;

  @override
  Color get clipBackgroundColor => ArrangementClipTheme.sampleClipBackground;

  @override
  Color get clipContentBackgroundColor =>
      ArrangementClipTheme.contentBackground(clipBackgroundColor);

  @override
  String? get headerLabel {
    return clip.sampleName.isNotEmpty ? clip.sampleName : 'Sample';
  }

  @override
  void paintContent(Canvas canvas, Rect contentRect) {
    final peaks = clip.waveformPeaks;
    if (peaks.isEmpty || contentRect.width <= 0 || contentRect.height <= 0) {
      return;
    }

    final paint = Paint()
      ..color = ArrangementClipTheme.sampleWaveform
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final midY = contentRect.center.dy;
    final halfHeight = contentRect.height / 2;
    final step = contentRect.width / peaks.length;

    for (var i = 0; i < peaks.length; i++) {
      final peak = peaks[i].clamp(0.0, 1.0);
      final x = contentRect.left + i * step + step / 2;
      final half = peak * halfHeight;
      canvas.drawLine(
        Offset(x, midY - half),
        Offset(x, midY + half),
        paint,
      );
    }
  }
}
