part of 'wavetable_waveform_preview.dart';

class _Wavetable3DPainter extends CustomPainter {
  _Wavetable3DPainter({
    required this.accent,
    this.frames,
    required this.frameLength,
    required this.frameCount,
    required this.wtPosition,
  });

  final Color accent;
  final Float64List? frames;
  final int frameLength;
  final int frameCount;
  final double wtPosition;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final data = frames;
    if (data == null || frameCount <= 0 || frameLength <= 1) {
      _drawPlaceholder(canvas, size);
      return;
    }

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(6),
      ),
    );

    final activeFrame = (wtPosition * (frameCount - 1))
        .clamp(
          0.0,
          (frameCount - 1).toDouble(),
        )
        .toDouble();
    final activeIndex = activeFrame.round().clamp(0, frameCount - 1);

    final targetVisible = math.max(8, math.min(48, (size.width / 5.0).round()));
    final visibleCount = math.min(frameCount, targetVisible);

    final stackDepthY = size.height * 0.28;
    final stackDepthX = math.min(size.width * 0.12, 18.0);

    final verticalPad = size.height * 0.04;
    final amplitude = math.max(
      2.0,
      (size.height - stackDepthY - verticalPad * 2.0) * 0.5,
    );

    final centerBaseY = size.height * 0.5;
    final xPad = stackDepthX * 0.55 + 2.0;
    final pointCount = math.max(
        24, math.min(frameLength, math.min(256, (size.width * 2).round())));

    void drawFrame({
      required int frameIndex,
      required double depth,
      required bool active,
    }) {
      final offset = frameIndex * frameLength;
      if (offset + frameLength > data.length) return;

      final yShift = _lerp(-stackDepthY * 0.5, stackDepthY * 0.5, depth);
      final xShift = _lerp(stackDepthX * 0.5, -stackDepthX * 0.5, depth);

      final centerY = centerBaseY + yShift;
      final startX = xPad + xShift;
      final endX = size.width - xPad + xShift;

      final activeDistance =
          (frameIndex - activeFrame).abs() / math.max(frameCount - 1, 1);
      final activeGlow =
          math.pow((1.0 - activeDistance).clamp(0.0, 1.0), 4.0).toDouble();

      final alpha = active
          ? 0.95
          : (0.08 + depth * 0.22 + activeGlow * 0.18)
              .clamp(0.08, 0.5)
              .toDouble();

      final strokeWidth = active ? 2.0 : _lerp(0.55, 1.1, depth);

      final path = Path();
      for (int p = 0; p < pointCount; ++p) {
        final t = pointCount <= 1 ? 0.0 : p / (pointCount - 1);
        final sampleIndex =
            math.min(frameLength - 1, (t * (frameLength - 1)).round());
        final x = _lerp(startX, endX, t);
        final sample = data[offset + sampleIndex];
        final y = centerY - sample * amplitude;

        if (p == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final fillPath = Path.from(path)
        ..lineTo(endX, centerY)
        ..lineTo(startX, centerY)
        ..close();

      final fillPaint = Paint()
        ..color = accent.withValues(alpha: active ? 0.16 : alpha * 0.18)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final strokePaint = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    for (int i = 0; i < visibleCount; ++i) {
      final depth = visibleCount <= 1 ? 1.0 : i / (visibleCount - 1);
      final frameIndex = visibleCount <= 1
          ? 0
          : ((i / (visibleCount - 1)) * (frameCount - 1)).round();

      if (frameIndex == activeIndex) continue;
      drawFrame(frameIndex: frameIndex, depth: depth, active: false);
    }

    final activeDepth = frameCount <= 1 ? 1.0 : activeFrame / (frameCount - 1);
    drawFrame(frameIndex: activeIndex, depth: activeDepth, active: true);

    canvas.restore();
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    const int pts = 128;

    final paint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final midY = size.height / 2;
    final h = size.height * 0.35;
    final path = Path();

    for (int i = 0; i < pts; ++i) {
      final x = (i / (pts - 1)) * size.width;
      final t = i / pts;
      final y = midY - _fastSin(t * 6.2832) * h;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  static double _fastSin(double x) {
    double y = x - (x / 6.2832).floor() * 6.2832;
    if (y > 3.1416) y -= 6.2832;
    final y2 = y * y;
    return y * (1.0 - y2 * (1.0 / 6.0 - y2 * (1.0 / 120.0 - y2 / 5040.0)));
  }

  @override
  bool shouldRepaint(covariant _Wavetable3DPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.frames != frames ||
        oldDelegate.frameLength != frameLength ||
        oldDelegate.frameCount != frameCount ||
        oldDelegate.wtPosition != wtPosition;
  }
}
