part of '../dynamics_envelope_preview.dart';

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
