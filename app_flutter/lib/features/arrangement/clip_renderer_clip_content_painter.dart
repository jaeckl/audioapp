part of 'clip_renderer.dart';

class _ClipContentPainter extends CustomPainter {
  const _ClipContentPainter({required this.renderer});

  final ClipRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = renderer.clipContentBackgroundColor,
    );
    renderer.paintContent(canvas, rect);
    if (renderer.loopContentEnabled) {
      _paintLoopBadge(canvas, rect);
    }
    final badgeLabel = renderer.contentBadgeLabel;
    if (badgeLabel != null) {
      _paintModeBadge(canvas, rect, badgeLabel);
    }
  }

  void _paintLoopBadge(Canvas canvas, Rect rect) {
    const size = 10.0;
    final badgeRect = Rect.fromLTWH(
      rect.right - size - 2,
      rect.top + 2,
      size,
      size,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\u21BB',
        style: TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 9,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - textPainter.width) / 2,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  void _paintModeBadge(Canvas canvas, Rect rect, String label) {
    const height = 11.0;
    const hPad = 3.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xE6FFFFFF),
          fontSize: 7,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = textPainter.width + hPad * 2;
    final badgeRect = Rect.fromLTWH(rect.left + 2, rect.top + 2, width, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(2)),
      Paint()..color = const Color(0x99000000),
    );
    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + hPad,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ClipContentPainter oldDelegate) {
    return oldDelegate.renderer != renderer;
  }
}
