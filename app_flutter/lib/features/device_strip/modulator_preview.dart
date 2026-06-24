import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'modulator_math.dart';
import 'modulator_types.dart';

/// Square live preview of a modulator curve with a phase/playhead dot.
class ModulatorPreview extends StatelessWidget {
  const ModulatorPreview({
    super.key,
    required this.mod,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.accent,
    this.isSelected = false,
    this.isConnectMode = false,
    this.innerPadding = 2.0,
  });

  static const tileRadius = 6.0;
  static const plotRadius = 4.0;

  final LfoSnapshot mod;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final Color accent;
  final bool isSelected;
  final bool isConnectMode;
  final double innerPadding;

  @override
  Widget build(BuildContext context) {
    final showBorder = isSelected || isConnectMode;
    final borderColor = isConnectMode
        ? accent
        : isSelected
            ? accent.withValues(alpha: 0.75)
            : Colors.transparent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(tileRadius),
        border: showBorder
            ? Border.all(
                color: borderColor,
                width: isConnectMode ? 1.5 : 1.0,
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(plotRadius),
          child: CustomPaint(
            painter: _ModulatorCurvePainter(
              mod: mod,
              playheadBeat: playheadBeat,
              bpm: bpm,
              elapsedSeconds: elapsedSeconds,
              accent: accent,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _ModulatorCurvePainter extends CustomPainter {
  _ModulatorCurvePainter({
    required this.mod,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.accent,
  });

  final LfoSnapshot mod;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Offset.zero & size;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final midY = plot.top + plot.height * 0.5;
    canvas.drawLine(Offset(plot.left, midY), Offset(plot.right, midY), grid);

    final points = ModulatorMath.curvePoints(mod);
    final curve = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = plot.left + p.dx * plot.width;
      final y = plot.bottom - p.dy * plot.height;
      if (i == 0) {
        curve.moveTo(x, y);
      } else {
        curve.lineTo(x, y);
      }
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    final dot = ModulatorMath.phaseDot(
      mod: mod,
      playheadBeat: playheadBeat,
      bpm: bpm,
      elapsedSeconds: elapsedSeconds,
    );
    final dotCenter = Offset(
      plot.left + dot.x * plot.width,
      plot.bottom - dot.y * plot.height,
    );
    final dotRadius = math.min(2.8, plot.shortestSide * 0.08);
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = accent);
    canvas.drawCircle(
      dotCenter,
      dotRadius + 1.6,
      Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final label = ModulatorTypes.labelFor(mod.modulatorType);
    final tp = TextPainter(
      text: TextSpan(
        text: '$label ${mod.id}',
        style: TextStyle(
          color: accent.withValues(alpha: 0.85),
          fontSize: math.min(8, plot.shortestSide * 0.22),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: plot.width - 4);
    tp.paint(canvas, Offset(plot.left + 2, plot.top + 1));
  }

  @override
  bool shouldRepaint(covariant _ModulatorCurvePainter oldDelegate) {
    return oldDelegate.mod != mod ||
        oldDelegate.playheadBeat != playheadBeat ||
        oldDelegate.elapsedSeconds != elapsedSeconds;
  }
}
