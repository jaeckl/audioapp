import 'package:flutter/material.dart';

import 'modulator_math.dart';

/// Paints a static preview of a morphed LFO waveform showing one full cycle.
///
/// Polarity ±: shows center line + transparent fill from center
/// Polarity +: no center line, fill from bottom
class LfoPreviewPainter extends CustomPainter {
  LfoPreviewPainter({
    required this.morph,
    required this.spread,
    this.polarity = 0,
    this.analogMode = 0,
    this.accent = const Color(0xFFE8A54B),
    this.backgroundColor = const Color(0xFF1C1C26),
  });

  final double morph;
  final double spread;
  final int polarity;
  final int analogMode;
  final Color accent;
  final Color backgroundColor;

  static const _analogMorph = 0.0;
  static const _analogSpread = 0.5;

  // Margin inside the paint area
  static const _vmargin = 4.0; // 4px top/bottom margin
  static const _samplesPerCycle = 100;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Background
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    canvas.save();
    canvas.clipRect(rect);

    final w = size.width;
    final h = size.height;

    // Effective morph/spread (analog overrides)
    final effMorph = analogMode != 0 ? _analogMorph : morph;
    final effSpread = analogMode != 0 ? _analogSpread : spread;

    // Center line for bipolar
    final centerY = h / 2;

    if (polarity == 0) {
      // ± bipolar: draw center line
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(0, centerY), Offset(w, centerY), linePaint);
    }

    // Fill area
    final fillPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Build waveform points
    final points = <Offset>[];
    for (var i = 0; i <= _samplesPerCycle; i++) {
      final phase = i / _samplesPerCycle;
      final value = ModulatorMath.lfoWaveMorph(effMorph, effSpread, phase);

      // Apply polarity
      final displayVal = polarity == 0 ? value : (value + 1.0) / 2.0;

      // Clamp to visible range
      final clamped = displayVal.clamp(-1.0, 1.0);

      final x = (phase * w);
      final y = polarity == 0
          ? centerY - clamped * (h / 2 - _vmargin)
          : h - _vmargin - clamped * (h - _vmargin * 2);

      points.add(Offset(x, y));
    }

    // Build fill path
    final fillPath = Path();
    fillPath.moveTo(points[0].dx, polarity == 0 ? centerY : h);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    if (polarity == 0) {
      fillPath.lineTo(points.last.dx, centerY);
    } else {
      fillPath.lineTo(points.last.dx, h);
    }
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw the waveform curve
    final curvePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final curvePath = Path();
    curvePath.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      curvePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(curvePath, curvePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(LfoPreviewPainter oldDelegate) =>
      morph != oldDelegate.morph ||
      spread != oldDelegate.spread ||
      polarity != oldDelegate.polarity ||
      analogMode != oldDelegate.analogMode;
}

/// A static LFO waveform preview with DG/AN toggle.
class LfoPreviewWidget extends StatelessWidget {
  const LfoPreviewWidget({
    super.key,
    required this.morph,
    required this.spread,
    required this.onChanged,
    this.polarity = 0,
    this.analogMode = 0,
  });

  final double morph;
  final double spread;
  final int polarity;
  final int analogMode;
  final void Function(String param, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8A54B);
    final isAnalog = analogMode != 0;
    final isBipolar = polarity == 0;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: LfoPreviewPainter(
              morph: morph,
              spread: spread,
              polarity: polarity,
              analogMode: analogMode,
            ),
            size: Size.infinite,
          ),
        ),
        // Top-right: DG/AN + Polarity toggle buttons
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Polarity toggle (± / +)
              GestureDetector(
                onTap: () => onChanged('polarity', isBipolar ? 1.0 : 0.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBipolar
                        ? Colors.white.withValues(alpha: 0.08)
                        : accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isBipolar ? Colors.white24 : accent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isBipolar ? '±' : '+',
                    style: TextStyle(
                      color: isBipolar ? Colors.white54 : accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              // DG/AN toggle
              GestureDetector(
                onTap: () => onChanged('analogMode', isAnalog ? 0.0 : 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAnalog
                        ? accent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isAnalog ? accent : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isAnalog ? 'AN' : 'DG',
                    style: TextStyle(
                      color: isAnalog ? accent : Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}