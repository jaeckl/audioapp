part of 'curve_properties_panel.dart';

class _CurvePreviewPainter extends CustomPainter {
  _CurvePreviewPainter({
    required this.positions,
    required this.values,
    required this.polarity,
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final int polarity;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1A1A24);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center line (for bipolar)
    if (polarity == 0) {
      final centerY = size.height / 2;
      canvas.drawLine(
          Offset(0, centerY),
          Offset(size.width, centerY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.1)
            ..strokeWidth = 0.5);
    }

    final count = positions.length;
    if (count < 2) return;

    // Build path
    final path = Path();
    final fillPath = Path();
    final zeroY = polarity == 0 ? size.height / 2 : size.height;
    bool first = true;
    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      if (first) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    // Close fill path to zero line
    final lastX = positions[count - 1].clamp(0.0, 1.0) * size.width;
    final firstX = positions[0].clamp(0.0, 1.0) * size.width;
    fillPath.lineTo(lastX, zeroY);
    fillPath.lineTo(firstX, zeroY);
    fillPath.close();

    // Fill
    canvas.drawPath(
        fillPath,
        Paint()
          ..color = accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill);

    // Curve line
    canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.9)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Dots at breakpoints
    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      canvas.drawCircle(
          Offset(x, y),
          3.0,
          Paint()
            ..color = accent
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_CurvePreviewPainter old) =>
      old.positions != positions ||
      old.values != values ||
      old.polarity != polarity;
}
