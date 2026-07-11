part of 'mod_strip.dart';

class _ReadoutPainter extends CustomPainter {
  _ReadoutPainter(this.value, this.color, this.center);
  final double value;
  final Color color;
  final bool center;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = const Color(0xFF2A2A30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      track,
    );
    if (center) {
      final midX = size.width / 2;
      canvas.drawLine(
        Offset(midX, 0),
        Offset(midX, size.height),
        Paint()..color = const Color(0xFF3A3A44),
      );
    }
    final clamped = value.clamp(center ? -1.0 : 0.0, 1.0);
    final fillPaint = Paint()..color = color.withValues(alpha: 0.85);
    if (center) {
      final midX = size.width / 2;
      final width = (clamped.abs() * (size.width / 2));
      final left = clamped >= 0 ? midX : midX - width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, width, size.height),
          const Radius.circular(2),
        ),
        fillPaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, clamped * size.width, size.height),
          const Radius.circular(2),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReadoutPainter old) =>
      old.value != value || old.color != color || old.center != center;
}
