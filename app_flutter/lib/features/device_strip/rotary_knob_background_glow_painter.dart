part of 'rotary_knob.dart';

class _BackgroundGlowPainter extends CustomPainter {
  _BackgroundGlowPainter({
    required this.glowColor,
    required this.borderRadius,
    required this.center,
  });

  final Color glowColor;
  final double borderRadius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: center,
      width: size.width - 4,
      height: size.height - 4,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor || oldDelegate.center != center;
  }
}
