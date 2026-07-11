part of 'rotary_knob.dart';

class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.value,
    required this.angle,
    required this.accentColor,
    this.strokeWidth = 3,
    this.modulationActive = false,
    this.modulationAmount = 0.0,
    this.modulatorPolarity = ModulatorPolarity.bipolar,
    this.connectModeActive = false,
    this.assignmentMode = false,
    this.assignmentAmount = 0.0,
  });

  final double value;
  final double angle;
  final Color accentColor;
  final double strokeWidth;
  final bool modulationActive;
  final double modulationAmount;
  final ModulatorPolarity modulatorPolarity;
  final bool connectModeActive;
  final bool assignmentMode;
  final double assignmentAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // --- Track arc ---
    // If connectModeActive, draw the whole track in accent with 30% alpha
    final trackPaint = Paint()
      ..color = connectModeActive
          ? accentColor.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      arcRect,
      KnobArcGeometry.start,
      KnobArcGeometry.sweep,
      false,
      trackPaint,
    );

    // --- Value arc ---
    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      arcRect,
      KnobArcGeometry.start,
      value * KnobArcGeometry.sweep,
      false,
      arcPaint,
    );

    // --- Modulation range arc (directional per modulator polarity) ---
    if (modulationActive && modulationAmount != 0.0) {
      final range = modulationKnobRange(
        polarity: modulatorPolarity,
        value: value,
        amount: modulationAmount,
      );
      final modStartAngle = KnobArcGeometry.indicatorAngle(range.low);
      final modSweepAngle =
          KnobArcGeometry.indicatorAngle(range.high) - modStartAngle;

      final modRect = connectModeActive
          ? Rect.fromCircle(center: center, radius: radius + strokeWidth)
          : arcRect;
      final modPaint = Paint()
        ..color = connectModeActive
            ? Colors.white.withValues(alpha: 0.5)
            : accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 0.5;
      canvas.drawArc(modRect, modStartAngle, modSweepAngle, false, modPaint);
    }

    // --- Assignment arc (connect-mode long-press drag visual) ---
    if (assignmentMode && assignmentAmount != 0.0) {
      final range = modulationKnobRange(
        polarity: modulatorPolarity,
        value: value,
        amount: assignmentAmount,
      );
      final startA = KnobArcGeometry.indicatorAngle(range.low);
      final sweepA = KnobArcGeometry.indicatorAngle(range.high) - startA;

      final assignRect = Rect.fromCircle(
        center: center,
        radius: radius + strokeWidth,
      );
      final assignPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 0.7;
      canvas.drawArc(assignRect, startA, sweepA, false, assignPaint);
    }

    // --- Indicator dot ---
    final indicatorPaint = Paint()..color = accentColor;
    final indicatorEnd = Offset(
      center.dx + math.cos(angle) * (radius - 4),
      center.dy + math.sin(angle) * (radius - 4),
    );
    canvas.drawCircle(indicatorEnd, 2.5, indicatorPaint);

    // --- Center fill ---
    final fillPaint = Paint()..color = const Color(0xFF14141C);
    canvas.drawCircle(center, radius - 6, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.angle != angle ||
        oldDelegate.modulationActive != modulationActive ||
        oldDelegate.modulationAmount != modulationAmount ||
        oldDelegate.modulatorPolarity != modulatorPolarity ||
        oldDelegate.connectModeActive != connectModeActive ||
        oldDelegate.assignmentMode != assignmentMode ||
        oldDelegate.assignmentAmount != assignmentAmount;
  }
}
