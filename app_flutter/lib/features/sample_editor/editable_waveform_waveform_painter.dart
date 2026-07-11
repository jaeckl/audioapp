part of 'editable_waveform.dart';

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(
      this.peaks,
      this.start,
      this.end,
      this.fadeIn,
      this.fadeOut,
      this.fadeInCurve,
      this.fadeOutCurve,
      this.gain,
      this.reversed,
      this.trimToolActive,
      this.fadeToolActive,
      this.sliceToolActive,
      this.sliceMarkers,
      this.selectedSlice,
      this.playhead);
  final List<double> peaks;
  final double start,
      end,
      fadeIn,
      fadeOut,
      fadeInCurve,
      fadeOutCurve,
      gain,
      playhead;
  final bool reversed;
  final bool trimToolActive, fadeToolActive;
  final bool sliceToolActive;
  final List<double> sliceMarkers;
  final int? selectedSlice;

  double _rawPeakAt(double position) {
    if (peaks.isEmpty) return 0;
    final source = position.clamp(0.0, 1.0) * (peaks.length - 1);
    final lo = source.floor();
    final hi = math.min(peaks.length - 1, lo + 1);
    final t = source - lo;
    final smooth = t * t * (3 - 2 * t);
    return (peaks[lo] + (peaks[hi] - peaks[lo]) * smooth).abs().clamp(0.0, 1.0);
  }

  double _fadeShape(double t, double curve) {
    final value = t.clamp(0.0, 1.0);
    if (curve < .165) return value;
    if (curve < .495) return value * value;
    if (curve < .83) return value * value * value;
    return value * value * (3 - 2 * value);
  }

  double _peakAt(double position) {
    if (position < start || position > end || end <= start) {
      return _rawPeakAt(position);
    }
    final progress = ((position - start) / (end - start)).clamp(0.0, 1.0);
    final sourcePosition = reversed ? end - progress * (end - start) : position;
    var envelope = 1.0;
    if (fadeIn > 0) envelope *= _fadeShape(progress / fadeIn, fadeInCurve);
    if (fadeOut > 0) {
      envelope *= _fadeShape((1 - progress) / fadeOut, fadeOutCurve);
    }
    return (_rawPeakAt(sourcePosition) * gain * envelope).clamp(0.0, 1.0);
  }

  Path _fadeInPath(Rect selected, double top, double bottom) {
    final path = Path()..moveTo(selected.left, bottom);
    final width = selected.width * fadeIn;
    if (width <= 0) return path;
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final x = selected.left + width * t;
      final y = bottom - (bottom - top) * _fadeShape(t, fadeInCurve);
      path.lineTo(x, y);
    }
    return path;
  }

  Path _fadeOutPath(Rect selected, double top, double bottom) {
    final path = Path();
    final width = selected.width * fadeOut;
    if (width <= 0) return path;
    final startX = selected.right - width;
    path.moveTo(startX, top);
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final x = startX + width * t;
      final y = top + (bottom - top) * (1 - _fadeShape(1 - t, fadeOutCurve));
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final shape = Path();
    final samples = math.max(peaks.length, size.width.ceil()).clamp(128, 4096);
    for (var i = 0; i <= samples; i++) {
      final p = i / samples;
      final x = p * size.width;
      final amp = _peakAt(p) * center * .82 + .6;
      if (i == 0) {
        shape.moveTo(x, center - amp);
      } else {
        shape.lineTo(x, center - amp);
      }
    }
    for (var i = samples; i >= 0; i--) {
      final p = i / samples;
      shape.lineTo(p * size.width, center + (_peakAt(p) * center * .82 + .6));
    }
    shape.close();
    canvas.drawPath(
        shape,
        Paint()
          ..color = const Color(0xff58cfc4).withValues(alpha: .72)
          ..isAntiAlias = true);
    canvas.drawPath(
        shape,
        Paint()
          ..color = const Color(0xffa1fff5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..isAntiAlias = true);

    final selected =
        Rect.fromLTRB(size.width * start, 0, size.width * end, size.height);
    final dim = Paint()..color = const Color(0xbb08080d);
    canvas.drawRect(Rect.fromLTRB(0, 0, selected.left, size.height), dim);
    canvas.drawRect(
        Rect.fromLTRB(selected.right, 0, size.width, size.height), dim);
    final curve = Paint()
      ..color = const Color(0xffb5a7ff)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final inX = selected.left + selected.width * fadeIn;
    final outX = selected.right - selected.width * fadeOut;
    const top = 10.0;
    final bottom = size.height - 10.0;
    if (fadeIn > 0) canvas.drawPath(_fadeInPath(selected, top, bottom), curve);
    if (fadeOut > 0)
      canvas.drawPath(_fadeOutPath(selected, top, bottom), curve);
    final handle = Paint()..color = const Color(0xffb5a7ff);
    if (fadeToolActive) {
      handle.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(inX, top), 11, handle);
      canvas.drawCircle(Offset(outX, top), 11, handle);
    }
    if (selectedSlice != null &&
        selectedSlice! >= 0 &&
        selectedSlice! <= sliceMarkers.length) {
      final bounds = <double>[0, ...sliceMarkers, 1];
      final left = selected.left + selected.width * bounds[selectedSlice!];
      final right = selected.left + selected.width * bounds[selectedSlice! + 1];
      canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height),
          Paint()..color = const Color(0x18ffd166));
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.peaks != peaks ||
      old.start != start ||
      old.end != end ||
      old.fadeIn != fadeIn ||
      old.fadeOut != fadeOut ||
      old.fadeInCurve != fadeInCurve ||
      old.fadeOutCurve != fadeOutCurve ||
      old.gain != gain ||
      old.reversed != reversed ||
      old.trimToolActive != trimToolActive ||
      old.fadeToolActive != fadeToolActive ||
      old.sliceToolActive != sliceToolActive ||
      old.sliceMarkers != sliceMarkers ||
      old.selectedSlice != selectedSlice ||
      old.playhead != playhead;
}
