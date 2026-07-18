part of 'split_device_panel.dart';

enum SplitPathKind { fork, merge }

/// Fork (1→2) or merge (2→1) signal path. Endpoints sit at [topY]/[bottomY]
/// (absolute px within the painter) so they line up with the gain knob centers.
class SplitPathPainter extends CustomPainter {
  const SplitPathPainter({
    required this.color,
    required this.kind,
    required this.topY,
    required this.bottomY,
  });

  final Color color;
  final SplitPathKind kind;
  final double topY;
  final double bottomY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final midY = (topY + bottomY) * 0.5;
    final spineX = size.width * 0.45;
    final path = Path();
    final dot = Paint()..color = color;

    if (kind == SplitPathKind.fork) {
      // One stem in from the left, split into two endpoints at knob centers.
      path
        ..moveTo(0, midY)
        ..lineTo(spineX, midY)
        ..moveTo(spineX, midY)
        ..quadraticBezierTo(spineX, topY, size.width, topY)
        ..moveTo(spineX, midY)
        ..quadraticBezierTo(spineX, bottomY, size.width, bottomY);
      canvas.drawPath(path, paint);
      canvas.drawCircle(Offset(0, midY), 2, dot);
      canvas.drawCircle(Offset(size.width, topY), 2, dot);
      canvas.drawCircle(Offset(size.width, bottomY), 2, dot);
    } else {
      // Two endpoints at knob centers merge into one stem out to the right.
      path
        ..moveTo(0, topY)
        ..quadraticBezierTo(spineX, topY, spineX, midY)
        ..moveTo(0, bottomY)
        ..quadraticBezierTo(spineX, bottomY, spineX, midY)
        ..moveTo(spineX, midY)
        ..lineTo(size.width, midY);
      canvas.drawPath(path, paint);
      canvas.drawCircle(Offset(0, topY), 2, dot);
      canvas.drawCircle(Offset(0, bottomY), 2, dot);
      canvas.drawCircle(Offset(size.width, midY), 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant SplitPathPainter old) =>
      old.color != color ||
      old.kind != kind ||
      old.topY != topY ||
      old.bottomY != bottomY;
}
