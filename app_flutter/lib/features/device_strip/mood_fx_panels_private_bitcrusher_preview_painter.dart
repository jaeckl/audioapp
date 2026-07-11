part of 'mood_fx_panels.dart';

class _BitcrusherPreviewPainter extends CustomPainter {
  _BitcrusherPreviewPainter({
    required this.rate,
    required this.bits,
    required this.accent,
  });

  final double rate;
  final double bits;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF07070A));
    final pad = math.max(8.0, size.shortestSide * .07);
    final graph =
        Rect.fromLTRB(pad, pad + 8, size.width - pad, size.height - pad);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = graph.left + graph.width * i / 4;
      final y = graph.top + graph.height * i / 4;
      canvas.drawLine(Offset(x, graph.top), Offset(x, graph.bottom), grid);
      canvas.drawLine(Offset(graph.left, y), Offset(graph.right, y), grid);
    }
    canvas.drawLine(
        graph.bottomLeft,
        graph.topRight,
        Paint()
          ..color = Colors.white.withValues(alpha: .28)
          ..strokeWidth = 1);
    final steps = (4 + rate * 8).round().clamp(4, 12);
    final levels = math.max(2, math.min(steps, bits.round()));
    final path = Path()..moveTo(graph.left, graph.bottom);
    for (var i = 0; i < steps; i++) {
      final x1 = graph.left + graph.width * (i + 1) / steps;
      final normalized = i / math.max(1, steps - 1);
      final quantized = (normalized * (levels - 1)).round() / (levels - 1);
      final y = graph.bottom - quantized * graph.height;
      if (i == 0) path.lineTo(graph.left, y);
      path.lineTo(x1, y);
      if (i < steps - 1) {
        final next =
            ((i + 1) / (steps - 1) * (levels - 1)).round() / (levels - 1);
        path.lineTo(x1, graph.bottom - next * graph.height);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.miter);
    final text = TextPainter(
      text: TextSpan(
          text: 'AMPLITUDE TRANSFER',
          style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 7,
              fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(pad, 5));
  }

  @override
  bool shouldRepaint(covariant _BitcrusherPreviewPainter old) =>
      old.rate != rate || old.bits != bits || old.accent != accent;
}
