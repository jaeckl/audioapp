part of 'granular_device_panel.dart';

class _GrainCloudPainter extends CustomPainter {
  const _GrainCloudPainter({
    required this.position,
    required this.grainSize,
    required this.density,
    required this.spray,
    required this.pitch,
  });

  final double position, grainSize, density, spray, pitch;

  @override
  void paint(Canvas canvas, Size size) {
    final count = 4 + (density * 18).round();
    final width = 7 + grainSize * 42;
    final slope = (pitch - .5) * 18;
    final centerY = size.height / 2;
    final axis = Paint()
      ..color = Colors.white.withValues(alpha: .1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(5, centerY), Offset(size.width - 5, centerY), axis);

    for (var i = 0; i < count; i++) {
      final seed = math.sin((i + 1) * 91.731);
      final normalized = count == 1 ? .5 : i / (count - 1);
      final x = 8 + normalized * (size.width - 16);
      final scatter = seed * spray * size.height * .34;
      final y = centerY + scatter;
      final half = width / 2;
      final alpha = .2 + .5 * (1 - (normalized - position).abs().clamp(0, 1));
      final paint = Paint()
        ..color = GranularDevicePanel.accent.withValues(alpha: alpha)
        ..strokeWidth = 1.4 + grainSize;
      final path = Path();
      for (var step = 0; step <= 10; step++) {
        final t = step / 10;
        final px = x - half + t * width;
        final envelope = math.sin(t * math.pi);
        final py = y + (t - .5) * slope * envelope;
        step == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
      }
      canvas.drawPath(path, paint);
      canvas.drawCircle(Offset(x, y), 1.5 + grainSize, paint);
    }

    final cursorX = 8 + position * (size.width - 16);
    canvas.drawLine(
      Offset(cursorX, 5),
      Offset(cursorX, size.height - 18),
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..strokeWidth = 1,
    );
    _paintText(canvas, '${(12 + grainSize * 180).round()} ms',
        const Offset(8, 5), Colors.white54, 8, TextAlign.left);
    _paintText(
        canvas,
        '${(5 + density * 39).round()} grains/s',
        Offset(size.width / 2, size.height - 14),
        Colors.white54,
        8,
        TextAlign.center);
    _paintText(canvas, '${((pitch - .5) * 48).round()} st',
        Offset(size.width - 8, 5), Colors.white54, 8, TextAlign.right);
  }

  @override
  bool shouldRepaint(_GrainCloudPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.grainSize != grainSize ||
      oldDelegate.density != density ||
      oldDelegate.spray != spray ||
      oldDelegate.pitch != pitch;
}
