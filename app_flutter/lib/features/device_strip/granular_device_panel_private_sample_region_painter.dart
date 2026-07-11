part of 'granular_device_panel.dart';

class _SampleRegionPainter extends CustomPainter {
  const _SampleRegionPainter({
    required this.peaks,
    required this.sampleName,
    required this.regionStart,
    required this.regionEnd,
    required this.position,
    required this.scan,
    required this.activeHandle,
  });

  final List<double> peaks;
  final String sampleName;
  final double regionStart, regionEnd, position, scan;
  final _RegionDrag? activeHandle;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final startX = regionStart * size.width;
    final endX = regionEnd * size.width;
    final region = Rect.fromLTRB(startX, 0, endX, size.height);
    canvas.drawRect(
      region,
      Paint()..color = GranularDevicePanel.accent.withValues(alpha: .08),
    );

    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..strokeWidth = 1;
    final count = math.max(peaks.length, 48);
    for (var i = 0; i < count; i++) {
      final x = i / math.max(1, count - 1) * size.width;
      final sourceIndex = peaks.isEmpty
          ? i
          : (i / count * peaks.length).floor().clamp(0, peaks.length - 1);
      final peak = peaks.isEmpty
          ? math.sin(i * .79) * .42
          : peaks[sourceIndex].abs().clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, centerY - peak * size.height * .34),
        Offset(x, centerY + peak * size.height * .34),
        wave,
      );
    }
    canvas.drawRect(
      Rect.fromLTRB(0, 0, startX, size.height),
      Paint()..color = Colors.black.withValues(alpha: .58),
    );
    canvas.drawRect(
      Rect.fromLTRB(endX, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: .58),
    );

    void handle(double x, String label, bool selected, bool left) {
      final color = selected ? Colors.white : GranularDevicePanel.accent;
      final paint = Paint()
        ..color = color
        ..strokeWidth = selected ? 2.5 : 2;
      canvas.drawLine(Offset(x, 3), Offset(x, size.height - 3), paint);
      final direction = left ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(x, 3)
        ..lineTo(x + direction * 10, 3)
        ..lineTo(x, 13)
        ..close();
      canvas.drawPath(path, paint);
      _paintText(canvas, label, Offset(x + direction * 7, size.height - 15),
          color, 8, TextAlign.center);
    }

    handle(startX, 'S', activeHandle == _RegionDrag.start, true);
    handle(endX, 'E', activeHandle == _RegionDrag.end, false);

    final cursorX = position.clamp(regionStart, regionEnd) * size.width;
    final cursorPaint = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(cursorX, 8), Offset(cursorX, size.height - 5), cursorPaint);
    canvas.drawCircle(Offset(cursorX, 7), 3, cursorPaint);

    final scanAmount = scan - .5;
    if (scanAmount.abs() > .025 && endX - startX > 12) {
      final direction = scanAmount.sign;
      final arrowEnd = (cursorX + direction * (12 + scanAmount.abs() * 34))
          .clamp(startX + 4, endX - 4);
      canvas.drawLine(Offset(cursorX, 16), Offset(arrowEnd, 16), cursorPaint);
      canvas.drawLine(
        Offset(arrowEnd, 16),
        Offset(arrowEnd - direction * 5, 12),
        cursorPaint,
      );
      canvas.drawLine(
        Offset(arrowEnd, 16),
        Offset(arrowEnd - direction * 5, 20),
        cursorPaint,
      );
    }
    _paintText(canvas, sampleName, Offset(size.width / 2, 4),
        Colors.white.withValues(alpha: .52), 9, TextAlign.center);
  }

  @override
  bool shouldRepaint(_SampleRegionPainter oldDelegate) =>
      oldDelegate.peaks != peaks ||
      oldDelegate.regionStart != regionStart ||
      oldDelegate.regionEnd != regionEnd ||
      oldDelegate.position != position ||
      oldDelegate.scan != scan ||
      oldDelegate.activeHandle != activeHandle;
}
