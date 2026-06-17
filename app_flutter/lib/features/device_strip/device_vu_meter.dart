import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

/// Vertical level meter between devices in the chain strip.
class DeviceVuMeter extends StatefulWidget {
  const DeviceVuMeter({
    super.key,
    required this.active,
    this.level = 0,
    this.gain = 1,
  });

  final bool active;
  final double level;
  final double gain;

  @override
  State<DeviceVuMeter> createState() => _DeviceVuMeterState();
}

class _DeviceVuMeterState extends State<DeviceVuMeter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _displayLevel = 0;
  final _rng = math.Random(7);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(DeviceVuMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
      if (_displayLevel > 0.02) {
        setState(() => _displayLevel = 0.02);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final target = widget.active
        ? (widget.level > 0
            ? widget.level.clamp(0.0, 1.0)
            : (0.18 + _rng.nextDouble() * 0.55) * widget.gain.clamp(0.0, 1.0))
        : 0.02;
    final next = _displayLevel + (target - _displayLevel) * 0.28;
    if ((next - _displayLevel).abs() > 0.002) {
      setState(() => _displayLevel = next.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DeviceVuMeterPainter(level: _displayLevel),
      child: const SizedBox.expand(),
    );
  }
}

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

    final fillRect = Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_low, _mid, _high],
        stops: const [0.0, 0.72, 1.0],
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
