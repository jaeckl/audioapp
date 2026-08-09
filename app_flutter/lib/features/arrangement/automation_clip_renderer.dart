import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'arrangement_clip_beat_layout.dart';
import 'arrangement_clip_loop_visual.dart';
import 'arrangement_clip_theme.dart';
import 'clip_renderer.dart';

part 'automation_clip_renderer_automation_clip_link_chip.dart';

/// Condensed automation curve preview for arrangement clips.
class AutomationClipRenderer extends ClipRenderer {
  const AutomationClipRenderer(this.clip, {this.trackAccent});

  final AutomationClipSnapshot clip;
  final Color? trackAccent;

  @override
  Color get clipBackgroundColor => trackAccent != null
      ? ArrangementClipTheme.clipBackgroundFromAccent(trackAccent!)
      : ArrangementClipTheme.automationClipBackground;

  @override
  Color get clipContentBackgroundColor =>
      ArrangementClipTheme.contentBackground(clipBackgroundColor);

  @override
  Color get clipBorderColor => trackAccent != null
      ? ArrangementClipTheme.clipBorderFromAccent(trackAccent!)
      : ArrangementClipTheme.automationClipBorder;

  @override
  Color get highlightBorderColor => trackAccent != null
      ? ArrangementClipTheme.clipHighlightFromAccent(trackAccent!)
      : ArrangementClipTheme.highlightBorder;

  @override
  Color get highlightShadowColor => highlightBorderColor;

  @override
  bool get loopContentEnabled => clip.loopContent;

  @override
  String? get headerLabel => null;

  @override
  String? get emptyPlaceholder => clip.isLinked ? null : 'AUTO';

  double get _contentLengthBeats => clip.loopContentLengthBeats;

  @override
  void paintContent(Canvas canvas, Rect contentRect) {
    final points = clip.points;
    if (points.isEmpty || clip.lengthBeats <= 0) {
      return;
    }

    final inner = contentRect.deflate(2);
    if (inner.width <= 0 || inner.height <= 0) {
      return;
    }

    final contentLength = _contentLengthBeats;
    final looping = clip.loopContent &&
        contentLength > 0 &&
        clip.lengthBeats > contentLength;

    if (looping) {
      ArrangementClipLoopVisual.paintRepeatRegions(
        canvas: canvas,
        contentRect: contentRect,
        contentLengthBeats: contentLength,
        clipLengthBeats: clip.lengthBeats,
        lengthBeats: clip.lengthBeats,
      );
    }

    final stroke = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void paintCurveTile(double tileOriginBeat, {required bool isRepeat}) {
      stroke.color = isRepeat
          ? (trackAccent != null
              ? ArrangementClipTheme.clipContentFillRepeatFromAccent(
                  trackAccent!)
              : ArrangementClipTheme.automationCurveRepeat)
          : (trackAccent != null
              ? ArrangementClipTheme.clipContentFillFromAccent(trackAccent!)
              : ArrangementClipTheme.automationCurve);

      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final x = ArrangementClipBeatLayout.beatToX(
          beat: tileOriginBeat + point.beat,
          contentRect: contentRect,
          lengthBeats: clip.lengthBeats,
        );
        final y = inner.bottom - point.value.clamp(0.0, 1.0) * inner.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, stroke);

      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            stroke.color.withValues(alpha: isRepeat ? 0.16 : 0.28),
            stroke.color.withValues(alpha: 0.02),
          ],
        ).createShader(inner);

      final tileRight = ArrangementClipBeatLayout.beatToX(
        beat: math.min(tileOriginBeat + contentLength, clip.lengthBeats),
        contentRect: contentRect,
        lengthBeats: clip.lengthBeats,
      );
      final fillPath = Path.from(path)
        ..lineTo(tileRight, inner.bottom)
        ..lineTo(
          ArrangementClipBeatLayout.beatToX(
            beat: tileOriginBeat,
            contentRect: contentRect,
            lengthBeats: clip.lengthBeats,
          ),
          inner.bottom,
        )
        ..close();
      canvas.drawPath(fillPath, fill);

      final dotPaint = Paint()..color = stroke.color;
      for (final point in points) {
        final x = ArrangementClipBeatLayout.beatToX(
          beat: tileOriginBeat + point.beat,
          contentRect: contentRect,
          lengthBeats: clip.lengthBeats,
        );
        final y = inner.bottom - point.value.clamp(0.0, 1.0) * inner.height;
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }

    if (looping) {
      for (var tileOriginBeat = 0.0;
          tileOriginBeat < clip.lengthBeats;
          tileOriginBeat += contentLength) {
        paintCurveTile(tileOriginBeat, isRepeat: tileOriginBeat > 0);
      }
      return;
    }

    paintCurveTile(0, isRepeat: false);
  }
}

/// Floating ~ toggle — tap to enter/exit link mode (no target label; clips may drive multiple params).
