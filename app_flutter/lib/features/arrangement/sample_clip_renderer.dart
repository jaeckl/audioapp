import 'dart:math' as math;

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
  bool get loopContentEnabled => clip.loopContent;

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
    final naturalBeats = clip.effectiveNaturalLengthBeats;
    final naturalPx =
        naturalBeats * (contentRect.width / clip.lengthBeats);
    final step = naturalPx / peaks.length;

    void paintWaveformAt(double tileLeft, double tileRight) {
      for (var i = 0; i < peaks.length; i++) {
        final peak = peaks[i].clamp(0.0, 1.0);
        final x = tileLeft + i * step + step / 2;
        if (x > tileRight) break;
        if (x < contentRect.left) continue;
        final half = peak * halfHeight;
        canvas.drawLine(
          Offset(x, midY - half),
          Offset(x, midY + half),
          paint,
        );
      }
    }

    if (clip.loopContent &&
        naturalBeats > 0 &&
        clip.lengthBeats > naturalBeats &&
        naturalPx > 0) {
      for (var tileLeft = contentRect.left;
          tileLeft < contentRect.right;
          tileLeft += naturalPx) {
        paintWaveformAt(tileLeft, math.min(tileLeft + naturalPx, contentRect.right));
      }
      return;
    }

    paintWaveformAt(contentRect.left, contentRect.right);
  }
}
