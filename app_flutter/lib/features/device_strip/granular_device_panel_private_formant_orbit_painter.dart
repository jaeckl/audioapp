part of 'granular_device_panel.dart';

class _FormantOrbitPainter extends CustomPainter {
  const _FormantOrbitPainter({
    required this.x,
    required this.y,
    required this.labels,
    required this.points,
    required this.xActive,
    required this.yActive,
  });

  final double x, y;
  final List<String> labels;
  final List<Offset> points;
  final bool xActive, yActive;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final loop = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      loop.lineTo(points[i].dx, points[i].dy);
    }
    loop.close();
    canvas.drawPath(
      loop,
      Paint()
        ..color = GranularDevicePanel.accent.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final selectedPoint = Offset(x * size.width, y * size.height);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      center,
      selectedPoint,
      Paint()
        ..color = GranularDevicePanel.accent.withValues(alpha: .38)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = GranularDevicePanel.accent.withValues(alpha: .18),
    );
    canvas.drawCircle(
      selectedPoint,
      9,
      Paint()..color = GranularDevicePanel.accent.withValues(alpha: .24),
    );
    canvas.drawCircle(
      selectedPoint,
      3.5,
      Paint()..color = GranularDevicePanel.accent,
    );

    for (var i = 0; i < points.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        points[i] - Offset(painter.width / 2, painter.height / 2),
      );
    }
    _paintText(
        canvas,
        'X',
        Offset(size.width - 3, size.height - 12),
        xActive ? GranularDevicePanel.accent : Colors.white38,
        8,
        TextAlign.right);
    _paintText(
        canvas,
        'Y',
        const Offset(3, 2),
        yActive ? GranularDevicePanel.accent : Colors.white38,
        8,
        TextAlign.left);
  }

  @override
  bool shouldRepaint(_FormantOrbitPainter oldDelegate) =>
      oldDelegate.x != x ||
      oldDelegate.y != y ||
      oldDelegate.xActive != xActive ||
      oldDelegate.yActive != yActive ||
      oldDelegate.points != points;
}
