import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'arrangement_clip_beat_layout.dart';
import 'arrangement_clip_loop_visual.dart';
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

    final naturalBeats =
        clip.warpRepitch ? clip.lengthBeats : clip.effectiveNaturalLengthBeats;
    final pixelsPerBeat = ArrangementClipBeatLayout.pixelsPerBeat(
      contentRect: contentRect,
      lengthBeats: clip.lengthBeats,
    );
    final naturalPx = naturalBeats * pixelsPerBeat;

    final looping = clip.loopContent &&
        naturalBeats > 0 &&
        clip.lengthBeats > naturalBeats &&
        naturalPx > 0;

    if (looping) {
      ArrangementClipLoopVisual.paintRepeatRegions(
        canvas: canvas,
        contentRect: contentRect,
        contentLengthBeats: naturalBeats,
        clipLengthBeats: clip.lengthBeats,
        lengthBeats: clip.lengthBeats,
      );
    }

    final paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final midY = contentRect.center.dy;
    final halfHeight = contentRect.height / 2;

    double cubicFade(double value, double curve) {
      final t = value.clamp(0.0, 1.0);
      final inv = 1 - t;
      return 3 * inv * inv * t * curve +
          3 * inv * t * t * (1 - curve) +
          t * t * t;
    }

    double peakAt(double position) {
      final phase = position.clamp(0.0, 1.0);
      final window = math.max(.001, clip.sourceEnd - clip.sourceStart);
      final sourcePhase = clip.reversed ? 1 - phase : phase;
      final source =
          (clip.sourceStart + sourcePhase * window) * (peaks.length - 1);
      final lo = source.floor();
      final hi = math.min(peaks.length - 1, lo + 1);
      final t = source - lo;
      final smooth = t * t * (3 - 2 * t);
      var envelope = 1.0;
      if (clip.fadeIn > 0) {
        envelope *= cubicFade(phase / clip.fadeIn, clip.fadeInCurve);
      }
      if (clip.fadeOut > 0) {
        envelope *= cubicFade((1 - phase) / clip.fadeOut, clip.fadeOutCurve);
      }
      return ((peaks[lo] + (peaks[hi] - peaks[lo]) * smooth) *
              clip.gain *
              envelope)
          .clamp(0.0, 1.0);
    }

    void paintWaveformAt(
      double tileOriginBeat,
      double tileEndBeat, {
      required bool isRepeat,
    }) {
      paint.color = isRepeat
          ? ArrangementClipTheme.sampleWaveformRepeat
          : ArrangementClipTheme.sampleWaveform;
      final tileLeft = ArrangementClipBeatLayout.beatToX(
        beat: tileOriginBeat,
        contentRect: contentRect,
        lengthBeats: clip.lengthBeats,
      );
      final tileRight = ArrangementClipBeatLayout.beatToX(
        beat: tileEndBeat,
        contentRect: contentRect,
        lengthBeats: clip.lengthBeats,
      );
      final visibleLeft = math.max(tileLeft, contentRect.left);
      final visibleRight = math.min(tileRight, contentRect.right);
      final tileWidth = math.max(1.0, tileRight - tileLeft);
      final barCount = math.max(1, ((visibleRight - visibleLeft) / 1.8).ceil());
      final step = (visibleRight - visibleLeft) / barCount;
      for (var i = 0; i < barCount; i++) {
        final x = visibleLeft + (i + .5) * step;
        final sourcePosition = (x - tileLeft) / tileWidth;
        final peak = peakAt(sourcePosition);
        final half = peak * halfHeight;
        canvas.drawLine(
          Offset(x, midY - half),
          Offset(x, midY + half),
          paint,
        );
      }
    }

    if (looping) {
      for (var tileOriginBeat = 0.0;
          tileOriginBeat < clip.lengthBeats;
          tileOriginBeat += naturalBeats) {
        final tileEndBeat =
            math.min(tileOriginBeat + naturalBeats, clip.lengthBeats);
        paintWaveformAt(
          tileOriginBeat,
          tileEndBeat,
          isRepeat: tileOriginBeat > 0,
        );
      }
      return;
    }

    // A normal one-shot keeps its natural source width. Extending the
    // arrangement container leaves a genuinely empty tail; only Repitch Warp
    // stretches content to the full clip and Loop paints repeated tiles.
    paintWaveformAt(
      0,
      math.min(naturalBeats, clip.lengthBeats),
      isRepeat: false,
    );
  }
}
