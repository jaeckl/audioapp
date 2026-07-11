part of 'sample_editor_screen.dart';

class _SampleRulerPainter extends CustomPainter {
  const _SampleRulerPainter({
    required this.pixelsPerBeat,
    required this.originX,
    required this.clipLengthBeats,
  });
  final double pixelsPerBeat;
  final double originX;
  final double clipLengthBeats;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = AutomationEditorTheme.rulerBackground);
    final active = Rect.fromLTWH(originX, size.height - 3,
        math.max(0, clipLengthBeats * pixelsPerBeat), 3);
    canvas.drawRect(active,
        Paint()..color = AutomationEditorTheme.accent.withValues(alpha: .8));
    final text = TextPainter(textDirection: TextDirection.ltr);
    final firstBeat = (-originX / pixelsPerBeat).floor();
    final lastBeat = ((size.width - originX) / pixelsPerBeat).ceil();
    for (var beat = firstBeat; beat <= lastBeat; beat++) {
      final x = originX + beat * pixelsPerBeat;
      final bar = beat % 4 == 0;
      canvas.drawLine(
          Offset(x, bar ? 0 : 12),
          Offset(x, size.height),
          Paint()
            ..color = bar ? Colors.white24 : Colors.white10
            ..strokeWidth = 1);
      if (pixelsPerBeat >= 42 || bar) {
        final barIndex = beat ~/ 4;
        final beatInBar = beat % 4;
        text.text = TextSpan(
            text: bar
                ? (barIndex < 0 ? '$barIndex' : '${barIndex + 1}')
                : barIndex < 0
                    ? '$barIndex.${beatInBar + 1}'
                    : '${barIndex + 1}.${beatInBar + 1}',
            style: TextStyle(
                fontSize: bar ? 9 : 8,
                fontWeight: beat == 0 ? FontWeight.w700 : FontWeight.w500,
                color: beat >= 0 && beat <= clipLengthBeats
                    ? AutomationEditorTheme.accent
                    : AutomationEditorTheme.labelMuted));
        text.layout();
        text.paint(canvas, Offset(x + 5, 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SampleRulerPainter old) =>
      old.pixelsPerBeat != pixelsPerBeat ||
      old.originX != originX ||
      old.clipLengthBeats != clipLengthBeats;
}
