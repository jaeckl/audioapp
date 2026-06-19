import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

class PianoRollRuler extends StatelessWidget {
  const PianoRollRuler({
    super.key,
    required this.virtualLengthBeats,
    required this.clipLengthBeats,
    required this.pixelsPerBeat,
    this.regionStartBeat = 0,
    this.highlightColor,
  });

  final double virtualLengthBeats;
  final double clipLengthBeats;
  final double pixelsPerBeat;
  final double regionStartBeat;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final width = PianoRollMetrics.gridWidth(virtualLengthBeats, pixelsPerBeat);
    final barCount = (virtualLengthBeats / PianoRollMetrics.beatsPerBar).ceil();

    return SizedBox(
      width: width,
      height: PianoRollMetrics.rulerHeight,
      child: CustomPaint(
        painter: _RulerPainter(
          barCount: barCount,
          clipLengthBeats: clipLengthBeats,
          regionStartBeat: regionStartBeat,
          highlightColor: highlightColor,
          pixelsPerBeat: pixelsPerBeat,
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.barCount,
    required this.clipLengthBeats,
    required this.regionStartBeat,
    required this.highlightColor,
    required this.pixelsPerBeat,
  });

  final int barCount;
  final double clipLengthBeats;
  final double regionStartBeat;
  final Color? highlightColor;
  final double pixelsPerBeat;

  static const double _laneInset = 3.0;
  static const double _laneVInset = 4.0;
  static const double _minPillWidth = 4.0;
  static const double _minLaneWidth = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bgPaint = Paint()..color = PianoRollTheme.rulerBackground;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final barHeight = size.height - _laneVInset * 2;
    if (barHeight <= 0) return;

    final barWidth = pixelsPerBeat * PianoRollMetrics.beatsPerBar;
    if (barWidth <= 0) return;

    final regionStartPx = (regionStartBeat * pixelsPerBeat).clamp(0.0, size.width);
    final regionEndPx = (clipLengthBeats * pixelsPerBeat).clamp(0.0, size.width);
    final radius = const Radius.circular(4);
    final accent = highlightColor ?? PianoRollTheme.accent;
    final activeFill = Paint()..color = accent.withValues(alpha: 0.28);
    final idleFill = Paint()..color = const Color(0xFF22222A);
    final activeEdge = Paint()..color = accent.withValues(alpha: 0.18);

    if (regionEndPx - regionStartPx >= _minLaneWidth) {
      final laneLeft = regionStartPx + _laneInset;
      final laneRight = regionEndPx - _laneInset;
      if (laneRight > laneLeft) {
        final laneWidth = (laneRight - laneLeft).clamp(0.0, size.width);
        if (laneWidth >= _minLaneWidth) {
          final laneRect = Rect.fromLTWH(laneLeft, _laneVInset, laneWidth, barHeight);
          canvas.drawRRect(RRect.fromRectAndRadius(laneRect, radius), activeEdge);
        }
      }
    }

    for (var bar = 0; bar < barCount; bar++) {
      final barStart = bar * barWidth;
      if (barStart >= size.width) break;

      final barEnd = barStart + barWidth;
      final inClipStart = barStart.clamp(regionStartPx, regionEndPx);
      final inClipEnd = barEnd.clamp(regionStartPx, regionEndPx);
      final inClip = inClipEnd > inClipStart;

      double pillLeft;
      double pillWidth;

      if (inClip) {
        pillLeft = inClipStart + _laneInset;
        pillWidth = (inClipEnd - inClipStart) - _laneInset * 2;
      } else {
        pillLeft = barStart + _laneInset;
        pillWidth = barWidth - _laneInset * 2;
      }

      if (pillWidth < _minPillWidth) {
        pillWidth = _minPillWidth;
      }
      if (pillWidth > size.width - pillLeft) {
        pillWidth = size.width - pillLeft;
      }
      if (pillWidth <= 0 || pillLeft < 0 || pillLeft >= size.width) continue;

      final pillRect = Rect.fromLTWH(pillLeft, _laneVInset, pillWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, radius),
        inClip ? activeFill : idleFill,
      );

      if (inClip) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${bar + 1}',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelX = barStart + (barWidth - tp.width) / 2;
        if (labelX >= 0 && labelX + tp.width <= size.width) {
          tp.paint(canvas, Offset(labelX, (size.height - tp.height) / 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.barCount != barCount ||
        oldDelegate.clipLengthBeats != clipLengthBeats ||
        oldDelegate.regionStartBeat != regionStartBeat ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat;
  }
}