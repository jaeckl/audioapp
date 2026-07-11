part of 'device_vu_meter.dart';

class _DeviceVuMeterPainter extends CustomPainter {
  const _DeviceVuMeterPainter({required this.level});

  final double level;

  static const _track = Color(0xFF101016);
  static const _low = Color(0xFF5FAF8C);
  static const _mid = Color(0xFFE8C45A);
  static const _high = Color(0xFFE87B8A);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = _track,
    );

    final fillHeight = size.height * level.clamp(0.0, 1.0);
    if (fillHeight <= 0) return;

    final fillRect =
        Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_low, _mid, _high],
        stops: [0.0, 0.72, 1.0],
      ).createShader(fillRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DeviceVuMeterPainter oldDelegate) {
    return (oldDelegate.level - level).abs() > 0.01;
  }
}
