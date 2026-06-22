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

    // The waveform's natural extent is the source sample's beat duration at
    // capture time. We size each peak to that natural beat-width and anchor
    // the waveform to the LEFT edge of the clip:
    //   - clip.lengthBeats <  naturalLengthBeats  →  waveform clips
    //     (only the prefix that fits is drawn; trailing space is empty)
    //   - clip.lengthBeats >= naturalLengthBeats  →  trailing empty space
    //     (waveform keeps its natural density; right side is blank)
    final naturalPx = clip.effectiveNaturalLengthBeats *
        (contentRect.width / clip.lengthBeats);
    final step = naturalPx / peaks.length;

    for (var i = 0; i < peaks.length; i++) {
      final peak = peaks[i].clamp(0.0, 1.0);
      final x = contentRect.left + i * step + step / 2;
      // Skip peaks that fall outside the clip's content rect (clip mode).
      if (x > contentRect.right) break;
      if (x < contentRect.left) continue;
      final half = peak * halfHeight;
      canvas.drawLine(
        Offset(x, midY - half),
        Offset(x, midY + half),
        paint,
      );
    }
  }
}
