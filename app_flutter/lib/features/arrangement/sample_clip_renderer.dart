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

    final naturalBeats = clip.effectiveNaturalLengthBeats;
    final pixelsPerBeat = ArrangementClipBeatLayout.pixelsPerBeat(
      contentRect: contentRect,
      lengthBeats: clip.lengthBeats,
    );
    final naturalPx = naturalBeats * pixelsPerBeat;
    final step = naturalPx / peaks.length;

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

    void paintWaveformAt(
      double tileOriginBeat,
      double tileEndBeat, {
      required bool isRepeat,
    }) {
      paint.color =
          isRepeat ? ArrangementClipTheme.sampleWaveformRepeat : ArrangementClipTheme.sampleWaveform;
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

    if (looping) {
      for (var tileOriginBeat = 0.0;
          tileOriginBeat < clip.lengthBeats;
          tileOriginBeat += naturalBeats) {
        final tileEndBeat = math.min(tileOriginBeat + naturalBeats, clip.lengthBeats);
        paintWaveformAt(
          tileOriginBeat,
          tileEndBeat,
          isRepeat: tileOriginBeat > 0,
        );
      }
      return;
    }

    paintWaveformAt(0, clip.lengthBeats, isRepeat: false);
  }
}
