part of 'modulatable_spinner_shell.dart';

class _SpinnerBackgroundGlowPainter extends CustomPainter {
  _SpinnerBackgroundGlowPainter({
    required this.glowColor,
    required this.borderRadius,
  });

  final Color glowColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerBackgroundGlowPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor;
  }
}
