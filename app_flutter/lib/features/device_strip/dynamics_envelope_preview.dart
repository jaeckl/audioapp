import 'package:flutter/material.dart';

class DynamicsEnvelopePreview extends StatelessWidget {
  const DynamicsEnvelopePreview({
    super.key,
    required this.threshold,
    required this.accent,
    this.mode = DynamicsPreviewMode.gate,
    this.ratio = 0.5,
    this.ceiling = 0.85,
  });

  final double threshold;
  final Color accent;
  final DynamicsPreviewMode mode;
  final double ratio;
  final double ceiling;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DynamicsEnvelopePainter(
        threshold: threshold,
        accent: accent,
        mode: mode,
        ratio: ratio,
        ceiling: ceiling,
      ),
      child: const SizedBox.expand(),
    );
  }
}

enum DynamicsPreviewMode { gate, compressor, expander, limiter }

class _DynamicsEnvelopePainter extends CustomPainter {
  _DynamicsEnvelopePainter({
    required this.threshold,
    required this.accent,
    required this.mode,
    required this.ratio,
    required this.ceiling,
  });

  final double threshold;
  final Color accent;
  final DynamicsPreviewMode mode;
  final double ratio;
  final double ceiling;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0E0E14));

    final thresholdY = size.height * (1.0 - threshold.clamp(0.0, 1.0));
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..strokeWidth = 1.5,
    );

    final path = Path()..moveTo(0, size.height);
    switch (mode) {
      case DynamicsPreviewMode.gate:
        final openX = size.width * (0.15 + threshold * 0.35);
        path
          ..lineTo(openX, size.height)
          ..lineTo(openX + 40, size.height * 0.12)
          ..lineTo(size.width * 0.72, size.height * 0.12)
          ..lineTo(size.width * 0.82, size.height);
      case DynamicsPreviewMode.compressor:
        final kneeX = size.width * threshold.clamp(0.2, 0.8);
        path
          ..lineTo(kneeX - 30, size.height * 0.15)
          ..lineTo(kneeX, size.height * 0.15)
          ..lineTo(size.width, size.height * (0.15 + (1.0 - ratio) * 0.45));
      case DynamicsPreviewMode.expander:
        final kneeX = size.width * threshold.clamp(0.2, 0.7);
        path
          ..lineTo(kneeX, size.height * 0.18)
          ..lineTo(0, size.height * (0.18 + ratio * 0.55));
      case DynamicsPreviewMode.limiter:
        final ceilY = size.height * (1.0 - ceiling.clamp(0.0, 1.0));
        path
          ..lineTo(size.width * 0.55, size.height * 0.08)
          ..lineTo(size.width * 0.55, ceilY)
          ..lineTo(size.width, ceilY);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.55), accent.withValues(alpha: 0.08)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _DynamicsEnvelopePainter oldDelegate) =>
      oldDelegate.threshold != threshold ||
      oldDelegate.accent != accent ||
      oldDelegate.mode != mode ||
      oldDelegate.ratio != ratio ||
      oldDelegate.ceiling != ceiling;
}

String dynamicsThresholdLabel(double norm) =>
    '${(-60 + norm.clamp(0.0, 1.0) * 54).round()} dB';

String dynamicsRatioLabel(double norm, {bool expander = false}) {
  if (expander) {
    final r = 1 + norm.clamp(0.0, 1.0) * 7;
    return '${r.toStringAsFixed(1)}:1';
  }
  return '${(1 + norm.clamp(0.0, 1.0) * 19).round()}:1';
}

String dynamicsTimeLabel(double norm) {
  final ms = 0.5 + norm.clamp(0.0, 1.0) * 50;
  return ms < 1 ? '${(ms * 1000).round()} µs' : '${ms.toStringAsFixed(1)} ms';
}

String dynamicsCeilingLabel(double norm) =>
    '${(-12 + norm.clamp(0.0, 1.0) * 12).toStringAsFixed(1)} dB';

String dynamicsRangeLabel(double norm) =>
    '${(-80 + norm.clamp(0.0, 1.0) * 80).round()} dB';

String dynamicsMakeupLabel(double norm) => '+${(norm.clamp(0.0, 1.0) * 18).toStringAsFixed(1)} dB';

String dynamicsDriveLabel(double norm) => '+${(norm.clamp(0.0, 1.0) * 12).toStringAsFixed(1)} dB';

String dynamicsHoldLabel(double norm) => '${(norm.clamp(0.0, 1.0) * 80).round()} ms';
