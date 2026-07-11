part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterDrawgrid on EnvelopePreviewPainter {
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;

    for (final yFrac in [0.1, 0.5, 0.9]) {
      final y = size.height * (1.0 - yFrac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 1; i <= 3; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }
}
