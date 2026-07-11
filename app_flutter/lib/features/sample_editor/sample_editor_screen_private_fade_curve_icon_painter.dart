part of 'sample_editor_screen.dart';

class _FadeCurveIconPainter extends CustomPainter {
  const _FadeCurveIconPainter({
    required this.kind,
    required this.fadeOut,
    required this.color,
  });
  final _FadeCurveKind kind;
  final bool fadeOut;
  final Color color;

  double _shape(double value) => switch (kind) {
        _FadeCurveKind.linear => value,
        _FadeCurveKind.quadratic => value * value,
        _FadeCurveKind.cubic => value * value * value,
        _FadeCurveKind.smooth => value * value * (3 - 2 * value),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 6, size.width - 16, size.height - 12);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .10)
      ..strokeWidth = 1;
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, grid);
    canvas.drawLine(rect.bottomLeft, rect.topLeft, grid);

    final path = Path();
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final x = rect.left + rect.width * t;
      final shaped = fadeOut ? 1 - _shape(1 - t) : _shape(t);
      final y = rect.bottom - rect.height * shaped;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FadeCurveIconPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.fadeOut != fadeOut ||
      oldDelegate.color != color;
}
