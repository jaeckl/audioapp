part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterComputebreakpoints on EnvelopePreviewPainter {
  List<Offset> computeBreakpoints(Size size) {
    final hasHold = curveType == _ahdsr;
    final hasDecay = curveType != _asr;
    final hasSustain = curveType != _adr;

    const minSeg = 0.02;
    const eps = 0.01;
    final hasDelaySeg = delay > eps;
    final dl = hasDelaySeg ? math.max(eps, delay) : 0.0;
    final a = math.max(eps, attack);
    final h = hasHold ? math.max(eps, hold) : eps;
    final d = hasDecay ? math.max(eps, decay) : eps;
    final s = hasSustain ? math.max(eps, sustain * 0.3) : eps;
    final r = math.max(eps, release);

    double total;
    if (curveType == _adsr) {
      total = dl + a + d + s + r;
    } else if (curveType == _asr) {
      total = dl + a + s + r;
    } else if (curveType == _adr) {
      total = dl + a + d + r;
    } else {
      total = dl + a + h + d + s + r;
    }

    final w = size.width;
    final hPx = size.height;
    final points = <Offset>[];
    double x = 0;

    // Start at (0, bottom)
    points.add(Offset(0, hPx));

    // Delay: flat at bottom (only when non-zero)
    if (hasDelaySeg) {
      x += math.max(minSeg * w, dl / total * w);
      points.add(Offset(x, hPx));
    }

    // Attack: bottom → peak
    x += math.max(minSeg * w, a / total * w);
    points.add(Offset(x, 0));

    // Hold (AHDSR only): flat at peak
    if (hasHold) {
      x += math.max(minSeg * w, h / total * w);
      points.add(Offset(x, 0));
    }

    // Decay: peak → sustain level
    if (hasDecay) {
      x += math.max(minSeg * w, d / total * w);
      final susY = (1.0 - sustain.clamp(0.0, 1.0)) * hPx;
      points.add(Offset(x, susY));
    }

    // Sustain: flat at sustain level
    if (hasSustain) {
      final susY = (1.0 - sustain.clamp(0.0, 1.0)) * hPx;
      x += math.max(minSeg * w, s / total * w);
      points.add(Offset(x, susY));
    }

    // Release: sustain level → bottom
    x += math.max(minSeg * w, r / total * w);
    points.add(Offset(math.min(x, w), hPx));

    return points;
  }
}
