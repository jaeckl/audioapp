part of 'time_fx_panels.dart';

class _ReverbResponsePainter extends CustomPainter {
  const _ReverbResponsePainter({
    required this.view,
    required this.device,
    required this.accent,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.assignmentParameter,
    required this.assignmentAmount,
  });

  final ReverbViewTab view;
  final ReverbDeviceSnapshot device;
  final Color accent;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final String? assignmentParameter;
  final double assignmentAmount;

  void _text(Canvas canvas, String text, Offset offset, Color color,
      {double size = 7, FontWeight weight = FontWeight.w700}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _handle(Canvas canvas, String parameter, Offset center) {
    canvas.drawCircle(
      center,
      14,
      Paint()..color = accent.withValues(alpha: .12),
    );
    canvas.drawCircle(center, 6, Paint()..color = accent);
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke,
    );
    final amount = assignmentParameter == parameter
        ? assignmentAmount
        : modulationAmounts[parameter] ?? 0;
    if ((modulatedParams.contains(parameter) ||
            assignmentParameter == parameter) &&
        amount.abs() > 0) {
      canvas.drawLine(
        center,
        Offset(center.dx + amount * 28, center.dy),
        Paint()
          ..color = Colors.white60
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    if (automatedParams.contains(parameter)) {
      canvas.drawCircle(
        center.translate(7, -7),
        2.4,
        Paint()..color = const Color(0xFFB48CFF),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mode = [
      'ROOM',
      'PLATE',
      'HALL',
      'SPACE'
    ][device.modeMorph.round().clamp(0, 3)];
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), grid);
    }

    if (view == ReverbViewTab.tail) {
      final baseY = size.height - 11;
      final peakY = 25.0;
      final preX = 12 + device.preDelay * 55;
      final decayX = 70 + device.decay * (size.width - 82);
      _text(
        canvas,
        '$mode  ·  PRE ${(device.preDelay * 250).round()} ms  ·  RT60 ${(.15 * math.pow(100, device.decay)).toStringAsFixed(1)} s',
        const Offset(8, 8),
        Colors.white60,
        size: 8,
      );
      for (var i = 0; i < 6; i++) {
        final x = preX - 22 + i * 4.2;
        final height = 14 + ((i * 17) % 42);
        canvas.drawLine(
          Offset(x, baseY),
          Offset(x, baseY - height),
          Paint()
            ..color = accent.withValues(alpha: .65)
            ..strokeWidth = 1.1,
        );
      }
      final path = Path()
        ..moveTo(preX, baseY)
        ..cubicTo(
          preX + 8,
          peakY,
          preX + 28,
          peakY,
          decayX,
          baseY - 9,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      _handle(canvas, 'preDelay', Offset(preX, baseY));
      _handle(canvas, 'decay', Offset(decayX, baseY - 9));
    } else if (view == ReverbViewTab.tone) {
      final y = size.height * .3;
      final lowX = 12 + device.lowCut * 58;
      final highX = size.width - 12 - (1 - device.highCut) * 58;
      final dampingX = 70 + device.damping * (size.width - 140);
      _text(
        canvas,
        'LOW ${_formatHz((20 * math.pow(50, device.lowCut)).toDouble())}  ·  DAMP ${(device.damping * 100).round()}%  ·  HIGH ${_formatHz((2000 * math.pow(10, device.highCut)).toDouble())}  ·  DUCK ${(device.ducking * 100).round()}%',
        const Offset(8, 8),
        Colors.white60,
        size: 8,
      );
      final path = Path()
        ..moveTo(6, size.height - 20)
        ..cubicTo(lowX - 10, size.height - 20, lowX - 7, y, lowX, y)
        ..lineTo(highX, y + (1 - device.damping) * 28)
        ..cubicTo(highX + 7, size.height - 20, size.width - 9, size.height - 20,
            size.width - 6, size.height - 20);
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      _handle(canvas, 'lowCut', Offset(lowX, y));
      _handle(canvas, 'highCut', Offset(highX, y + (1 - device.damping) * 28));
      _handle(canvas, 'damping', Offset(dampingX, size.height * .46));
      final duckX = 12 + device.ducking * (size.width - 24);
      canvas.drawLine(
        Offset(12, size.height - 11),
        Offset(size.width - 12, size.height - 11),
        Paint()
          ..color = Colors.white12
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(12, size.height - 11),
        Offset(duckX, size.height - 11),
        Paint()
          ..color = accent
          ..strokeWidth = 2,
      );
      _handle(canvas, 'ducking', Offset(duckX, size.height - 11));
    } else {
      final amplitude = 12 + device.modulation * (size.height * .38);
      final path = Path();
      for (var x = 8.0; x <= size.width - 8; x += 2) {
        final phase = (x - 8) / (size.width - 16) * math.pi * 4;
        final y = size.height * .5 + math.sin(phase) * amplitude;
        if (x == 8) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      for (var line = 0; line < 4; line++) {
        canvas.drawPath(
          path.shift(Offset(0, line * 6.0 - 9)),
          Paint()
            ..color = accent.withValues(alpha: .08 + line * .05)
            ..style = PaintingStyle.stroke,
        );
      }
      final handleX = 12 + device.modulation * (size.width - 24);
      _handle(canvas, 'modulation', Offset(handleX, size.height - 13));
      _text(
        canvas,
        '$mode  ·  DEPTH ${(device.modulation * 100).round()}%  ·  8-LINE MOTION',
        const Offset(8, 8),
        Colors.white60,
        size: 8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReverbResponsePainter oldDelegate) => true;
}
