part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterDrawlabel on EnvelopePreviewPainter {
  void _drawLabel(Canvas canvas, String text, double x, double bottom) {
    final builder = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: accent.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    builder.paint(canvas, Offset(x - builder.width / 2, bottom + 4));
  }
}
