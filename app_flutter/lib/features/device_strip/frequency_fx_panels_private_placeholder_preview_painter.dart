part of 'frequency_fx_panels.dart';

class _PlaceholderPreviewPainter extends CustomPainter {
  _PlaceholderPreviewPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E0E14),
    );
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var x = 0.0; x <= size.width; x += 2) {
      final t = x / size.width;
      final y = size.height * 0.5 +
          math.sin(t * math.pi * 4 + 1.2) * size.height * 0.18 +
          math.sin(t * math.pi * 11) * size.height * 0.04;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlaceholderPreviewPainter old) =>
      old.accent != accent;
}
