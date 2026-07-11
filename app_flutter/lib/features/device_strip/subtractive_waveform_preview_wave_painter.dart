part of 'subtractive_waveform_preview.dart';

class _WavePainter extends CustomPainter {
  _WavePainter({required this.shape, required this.color});

  final double shape;
  final Color color;

  static const _samples = 140;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final amp = size.height * 0.36;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), grid);
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final path = Path();
    for (var i = 0; i <= _samples; i++) {
      final t = i / _samples;
      final phase = t * math.pi * 2;
      final y = midY - _morphSample(shape, phase) * amp;
      final x = 4 + t * (size.width - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width - 4, midY)
      ..lineTo(4, midY)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  double _morphSample(double shape, double phase) {
    final scaled = shape.clamp(0.0, 1.0) * 4.0;
    final i0 = scaled.floor().clamp(0, 4);
    final i1 = (i0 + 1).clamp(0, 4);
    final t = scaled - i0;
    final a = _discreteSample(i0, phase);
    final b = _discreteSample(i1, phase);
    return a * (1.0 - t) + b * t;
  }

  double _discreteSample(int wave, double phase) {
    return switch (wave) {
      0 => math.sin(phase),
      1 => phase <= math.pi
          ? (2 * phase / math.pi - 1)
          : (3 - 2 * phase / math.pi),
      2 => (2 / math.pi) * (phase - math.pi),
      3 => phase < math.pi ? 1.0 : -1.0,
      _ => phase < math.pi ? 1.0 : -0.2,
    };
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
