import 'dart:math' as math;

import 'package:flutter/material.dart';

const double dynamicsPreviewMinDb = -60;
const double dynamicsPreviewMaxDb = 0;

enum DynamicsPreviewMode { gate, compressor, expander, limiter }

double dynamicsThresholdDb(double norm) => -60 + norm.clamp(0.0, 1.0) * 54;
double dynamicsCeilingDb(double norm) => -12 + norm.clamp(0.0, 1.0) * 12;
double dynamicsCompressorRatio(double norm) => 1 + norm.clamp(0.0, 1.0) * 19;
double dynamicsExpanderRatio(double norm) => 1 + norm.clamp(0.0, 1.0) * 7;
double dynamicsKneeDb(double norm) => norm.clamp(0.0, 1.0) * 12;
double dynamicsRangeDb(double norm) => -80 + norm.clamp(0.0, 1.0) * 80;
double dynamicsMakeupDb(double norm) => norm.clamp(0.0, 1.0) * 18;
double dynamicsDriveDb(double norm) => norm.clamp(0.0, 1.0) * 12;

double _compressorGainDb(
    double inputDb, double thresholdDb, double ratio, double kneeDb) {
  if (kneeDb <= 0.001) {
    return inputDb <= thresholdDb
        ? 0
        : (thresholdDb - inputDb) * (1 - 1 / ratio);
  }
  final kneeStart = thresholdDb - kneeDb * 0.5;
  final kneeEnd = thresholdDb + kneeDb * 0.5;
  if (inputDb <= kneeStart) return 0;
  if (inputDb >= kneeEnd) {
    return (thresholdDb - inputDb) * (1 - 1 / ratio);
  }
  final x = inputDb - kneeStart;
  final slope = (1 - 1 / ratio) / (2 * kneeDb);
  return -slope * x * x;
}

double _limiterGainDb(double inputDb, double ceilingDb, double kneeDb) {
  if (inputDb <= ceilingDb - kneeDb) return 0;
  if (inputDb >= ceilingDb) return ceilingDb - inputDb;
  if (kneeDb <= 0.001) return 0;
  final x = inputDb - (ceilingDb - kneeDb);
  return -0.5 * x * x / kneeDb;
}

/// Static input/output response matching `DynamicsProcessor.cpp`.
double dynamicsPreviewOutputDb({
  required DynamicsPreviewMode mode,
  required double inputDb,
  required double threshold,
  double ratio = 0.5,
  double knee = 0,
  double range = 0,
  double makeup = 0,
  double drive = 0,
  double ceiling = 0.85,
}) {
  switch (mode) {
    case DynamicsPreviewMode.gate:
      return inputDb >= dynamicsThresholdDb(threshold)
          ? inputDb
          : inputDb + dynamicsRangeDb(range);
    case DynamicsPreviewMode.compressor:
      return inputDb +
          _compressorGainDb(
            inputDb,
            dynamicsThresholdDb(threshold),
            dynamicsCompressorRatio(ratio),
            dynamicsKneeDb(knee),
          ) +
          dynamicsMakeupDb(makeup);
    case DynamicsPreviewMode.expander:
      final thresholdDb = dynamicsThresholdDb(threshold);
      final gainDb = inputDb < thresholdDb
          ? math.max(
              (inputDb - thresholdDb) * (dynamicsExpanderRatio(ratio) - 1),
              dynamicsRangeDb(range),
            )
          : 0.0;
      return inputDb + gainDb;
    case DynamicsPreviewMode.limiter:
      final drivenDb = inputDb + dynamicsDriveDb(drive);
      return drivenDb +
          _limiterGainDb(
            drivenDb,
            dynamicsCeilingDb(ceiling),
            dynamicsKneeDb(knee),
          ) +
          dynamicsMakeupDb(makeup);
  }
}

class DynamicsEnvelopePreview extends StatelessWidget {
  const DynamicsEnvelopePreview({
    super.key,
    required this.threshold,
    required this.accent,
    this.mode = DynamicsPreviewMode.gate,
    this.ratio = 0.5,
    this.knee = 0,
    this.range = 0,
    this.makeup = 0,
    this.drive = 0,
    this.ceiling = 0.85,
  });

  final double threshold;
  final Color accent;
  final DynamicsPreviewMode mode;
  final double ratio;
  final double knee;
  final double range;
  final double makeup;
  final double drive;
  final double ceiling;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DynamicsEnvelopePainter(
          threshold: threshold,
          accent: accent,
          mode: mode,
          ratio: ratio,
          knee: knee,
          range: range,
          makeup: makeup,
          drive: drive,
          ceiling: ceiling,
        ),
        child: const SizedBox.expand(),
      );
}

class _DynamicsEnvelopePainter extends CustomPainter {
  const _DynamicsEnvelopePainter({
    required this.threshold,
    required this.accent,
    required this.mode,
    required this.ratio,
    required this.knee,
    required this.range,
    required this.makeup,
    required this.drive,
    required this.ceiling,
  });

  final double threshold;
  final Color accent;
  final DynamicsPreviewMode mode;
  final double ratio;
  final double knee;
  final double range;
  final double makeup;
  final double drive;
  final double ceiling;

  Offset _point(Size size, double inputDb, double outputDb) {
    final x = (inputDb - dynamicsPreviewMinDb) /
        (dynamicsPreviewMaxDb - dynamicsPreviewMinDb);
    final y = (outputDb.clamp(dynamicsPreviewMinDb, dynamicsPreviewMaxDb) -
            dynamicsPreviewMinDb) /
        (dynamicsPreviewMaxDb - dynamicsPreviewMinDb);
    return Offset(size.width * x, size.height * (1 - y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0E0E14));

    final gridPaint = Paint()
      ..color = const Color(0xFF2C2C36).withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (final db in const [-45.0, -30.0, -15.0]) {
      final p = _point(size, db, db);
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, p.dy), Offset(size.width, p.dy), gridPaint);
    }

    canvas.drawLine(
      _point(size, dynamicsPreviewMinDb, dynamicsPreviewMinDb),
      _point(size, dynamicsPreviewMaxDb, dynamicsPreviewMaxDb),
      Paint()
        ..color = const Color(0xFF6A6A78).withValues(alpha: 0.7)
        ..strokeWidth = 1,
    );

    final markerDb = mode == DynamicsPreviewMode.limiter
        ? dynamicsCeilingDb(ceiling)
        : dynamicsThresholdDb(threshold);
    final marker = _point(size, markerDb, markerDb);
    final markerPaint = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(marker.dx, 0), Offset(marker.dx, size.height), markerPaint);
    canvas.drawLine(
        Offset(0, marker.dy), Offset(size.width, marker.dy), markerPaint);

    final response = Path();
    final fill = Path();
    const samples = 120;
    for (var i = 0; i <= samples; i++) {
      final inputDb = dynamicsPreviewMinDb +
          i / samples * (dynamicsPreviewMaxDb - dynamicsPreviewMinDb);
      final outputDb = dynamicsPreviewOutputDb(
        mode: mode,
        inputDb: inputDb,
        threshold: threshold,
        ratio: ratio,
        knee: knee,
        range: range,
        makeup: makeup,
        drive: drive,
        ceiling: ceiling,
      );
      final responsePoint = _point(size, inputDb, outputDb);
      final unityPoint = _point(size, inputDb, inputDb);
      if (i == 0) {
        response.moveTo(responsePoint.dx, responsePoint.dy);
        fill.moveTo(unityPoint.dx, unityPoint.dy);
      } else {
        response.lineTo(responsePoint.dx, responsePoint.dy);
        fill.lineTo(unityPoint.dx, unityPoint.dy);
      }
    }
    for (var i = samples; i >= 0; i--) {
      final inputDb = dynamicsPreviewMinDb +
          i / samples * (dynamicsPreviewMaxDb - dynamicsPreviewMinDb);
      fill.lineTo(
        _point(
          size,
          inputDb,
          dynamicsPreviewOutputDb(
            mode: mode,
            inputDb: inputDb,
            threshold: threshold,
            ratio: ratio,
            knee: knee,
            range: range,
            makeup: makeup,
            drive: drive,
            ceiling: ceiling,
          ),
        ).dx,
        _point(
          size,
          inputDb,
          dynamicsPreviewOutputDb(
            mode: mode,
            inputDb: inputDb,
            threshold: threshold,
            ratio: ratio,
            knee: knee,
            range: range,
            makeup: makeup,
            drive: drive,
            ceiling: ceiling,
          ),
        ).dy,
      );
    }
    fill.close();
    canvas.drawPath(fill, Paint()..color = accent.withValues(alpha: 0.14));
    canvas.drawPath(
      response,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DynamicsEnvelopePainter old) =>
      old.threshold != threshold ||
      old.accent != accent ||
      old.mode != mode ||
      old.ratio != ratio ||
      old.knee != knee ||
      old.range != range ||
      old.makeup != makeup ||
      old.drive != drive ||
      old.ceiling != ceiling;
}

String dynamicsThresholdLabel(double norm) =>
    '${dynamicsThresholdDb(norm).round()} dB';

String dynamicsRatioLabel(double norm, {bool expander = false}) {
  final ratio =
      expander ? dynamicsExpanderRatio(norm) : dynamicsCompressorRatio(norm);
  return expander ? '${ratio.toStringAsFixed(1)}:1' : '${ratio.round()}:1';
}

String dynamicsTimeLabel(double norm) {
  final ms = 0.5 + norm.clamp(0.0, 1.0) * 50;
  return ms < 1 ? '${(ms * 1000).round()} µs' : '${ms.toStringAsFixed(1)} ms';
}

String dynamicsCeilingLabel(double norm) =>
    '${dynamicsCeilingDb(norm).toStringAsFixed(1)} dB';
String dynamicsRangeLabel(double norm) => '${dynamicsRangeDb(norm).round()} dB';
String dynamicsMakeupLabel(double norm) =>
    '+${dynamicsMakeupDb(norm).toStringAsFixed(1)} dB';
String dynamicsDriveLabel(double norm) =>
    '+${dynamicsDriveDb(norm).toStringAsFixed(1)} dB';
String dynamicsHoldLabel(double norm) =>
    '${(norm.clamp(0.0, 1.0) * 80).round()} ms';
