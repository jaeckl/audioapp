part of 'filter_mode_icons.dart';

class FilterCurveIconPainter extends CustomPainter {
  FilterCurveIconPainter({
    required this.mode,
    required this.color,
    this.strokeWidth = 1.8,
  });

  final FilterCurveMode mode;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 5.0;
    final left = pad;
    final right = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;
    final midX = (left + right) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    switch (mode) {
      case FilterCurveMode.lowPass:
        path.moveTo(left, top + 1);
        path.lineTo(midX - 2, top + 1);
        path.quadraticBezierTo(right - 4, top + 2, right, bottom);
      case FilterCurveMode.highPass:
        path.moveTo(left, bottom);
        path.quadraticBezierTo(left + 4, top + 2, midX + 2, top + 1);
        path.lineTo(right, top + 1);
      case FilterCurveMode.bandPass:
        path.moveTo(left, bottom);
        path.quadraticBezierTo(midX - 6, top, midX, top + 1);
        path.quadraticBezierTo(midX + 6, top, right, bottom);
      case FilterCurveMode.notch:
        path.moveTo(left, top + 1);
        path.lineTo(midX - 7, top + 1);
        path.quadraticBezierTo(midX, bottom - 1, midX + 7, top + 1);
        path.lineTo(right, top + 1);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FilterCurveIconPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
