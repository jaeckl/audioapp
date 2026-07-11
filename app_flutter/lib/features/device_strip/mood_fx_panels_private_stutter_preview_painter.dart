part of 'mood_fx_panels.dart';

class _StutterPreviewPainter extends CustomPainter {
  _StutterPreviewPainter({
    required this.rateNorm,
    required this.windowNorm,
    required this.gate,
    required this.accent,
  });

  final double rateNorm;
  final double windowNorm;
  final double gate;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF101018);
    canvas.drawRect(Offset.zero & size, bg);

    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = accent.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final repeats = (3 + (1.0 - rateNorm) * 9).round();
    final gap = size.width / repeats;
    final activeW = (gap * (0.18 + windowNorm * 0.55)).clamp(3.0, gap);
    final activeH = size.height * (0.22 + gate.clamp(0.0, 1.0) * 0.58);
    for (var i = 0; i < repeats; i++) {
      final x = i * gap + gap * 0.12;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - activeH) / 2, activeW, activeH),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _StutterPreviewPainter old) =>
      old.rateNorm != rateNorm ||
      old.windowNorm != windowNorm ||
      old.gate != gate ||
      old.accent != accent;
}
