part of 'sample_editor_take_panel.dart';

class _TakeWavePainter extends CustomPainter {
  const _TakeWavePainter({
    required this.peaks,
    required this.take,
    required this.regions,
    required this.clipLengthBeats,
  });

  final List<double> peaks;
  final SampleClipTakeSnapshot take;
  final List<SampleClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;

  double _peakAt(double position) {
    if (peaks.isEmpty) return 0;
    final source = position.clamp(0.0, 1.0) * (peaks.length - 1);
    final lo = source.floor();
    final hi = math.min(peaks.length - 1, lo + 1);
    final t = source - lo;
    return (peaks[lo] + (peaks[hi] - peaks[lo]) * t).abs().clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final unavailable = Paint()
      ..color = Colors.black.withValues(alpha: .28)
      ..style = PaintingStyle.fill;
    final regionLine = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = 1;
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .30)
      ..strokeWidth = 1;
    final active = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: .22)
      ..style = PaintingStyle.fill;
    final activeBorder = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: .70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (clipLengthBeats > 0) {
      final availableLeft =
          (take.startBeatOffset / clipLengthBeats).clamp(0.0, 1.0) * size.width;
      final availableRight =
          ((take.startBeatOffset + take.lengthBeats) / clipLengthBeats)
                  .clamp(0.0, 1.0) *
              size.width;
      if (availableLeft > 0) {
        canvas.drawRect(
            Rect.fromLTRB(0, 0, availableLeft, size.height), unavailable);
      }
      if (availableRight < size.width) {
        canvas.drawRect(
            Rect.fromLTRB(availableRight, 0, size.width, size.height),
            unavailable);
      }

      for (final region in regions) {
        if (region.takeId != take.id) continue;
        final left =
            (region.startBeat / clipLengthBeats).clamp(0.0, 1.0) * size.width;
        final right =
            (region.endBeat / clipLengthBeats).clamp(0.0, 1.0) * size.width;
        if (right <= left) continue;
        final rect = Rect.fromLTRB(left, 5, right, size.height - 5);
        final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(7));
        canvas.drawRRect(rounded, active);
        canvas.drawRRect(rounded, activeBorder);
      }
    }

    if (peaks.isEmpty) {
      canvas.drawLine(Offset(0, center), Offset(size.width, center), wave);
    } else {
      final samples = math.max(size.width.ceil(), 128).clamp(128, 2048);
      for (var i = 0; i <= samples; i++) {
        final p = i / samples;
        final x = p * size.width;
        final peak = _peakAt(p);
        final half = 4 + peak * (size.height * .36);
        canvas.drawLine(
            Offset(x, center - half), Offset(x, center + half), wave);
      }
    }

    if (clipLengthBeats <= 0) return;
    for (final region in regions) {
      final x =
          (region.startBeat / clipLengthBeats).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), regionLine);
    }
  }

  @override
  bool shouldRepaint(covariant _TakeWavePainter oldDelegate) =>
      oldDelegate.peaks != peaks ||
      oldDelegate.take != take ||
      oldDelegate.regions != regions ||
      oldDelegate.clipLengthBeats != clipLengthBeats;
}
