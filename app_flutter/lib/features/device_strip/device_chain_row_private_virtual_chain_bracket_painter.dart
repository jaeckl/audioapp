part of 'device_chain_row.dart';

class _VirtualChainBracketPainter extends CustomPainter {
  const _VirtualChainBracketPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const tick = 9.0;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset.zero, const Offset(0, tick), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, tick), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - tick), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - tick), paint);
  }

  @override
  bool shouldRepaint(covariant _VirtualChainBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
