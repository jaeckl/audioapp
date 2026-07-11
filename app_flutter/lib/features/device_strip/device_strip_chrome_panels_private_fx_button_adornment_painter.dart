part of 'device_strip_chrome_panels.dart';

class _FxButtonAdornmentPainter extends CustomPainter {
  const _FxButtonAdornmentPainter({
    required this.accentColor,
    required this.active,
  });

  final Color accentColor;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    // Exact SVG path: M 0,3 V 0 H 40 V 3.
    final bracketPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final bracket = Path()
      ..moveTo(0, 3)
      ..lineTo(0, 0)
      ..lineTo(40, 0)
      ..lineTo(40, 3);
    canvas.drawPath(bracket, bracketPaint);

    // Exact SVG triangle: x=42.5..47.5, y=9..17, outside the button body.
    final triangle = Path()
      ..moveTo(47.5, 13)
      ..lineTo(42.5, 9)
      ..lineTo(42.5, 17)
      ..close();
    canvas.drawPath(
      triangle,
      Paint()
        ..color = const Color(0xFFF2F2F2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_FxButtonAdornmentPainter old) =>
      old.accentColor != accentColor || old.active != active;
}
