part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterCurvedsegments on EnvelopePreviewPainter {
  List<_SegmentCurve> curvedSegments(Size size) {
    if (!_adjustableCurves) return [];

    final pts = computeBreakpoints(size);
    if (pts.length < 3) return [];

    final result = <_SegmentCurve>[];
    final hasDelay = delay > 0.01;
    final hasHold = curveType == _ahdsr;
    final hasDecay = curveType != _asr;

    // Attack segment: index 1→2 (if delay) or 0→1 (no delay)
    final attackIdx = hasDelay ? 1 : 0;
    if (attackIdx + 1 < pts.length) {
      result.add(_SegmentCurve(
        param: 'attackCurve',
        xStart: pts[attackIdx].dx,
        xEnd: pts[attackIdx + 1].dx,
        yStart: pts[attackIdx].dy,
        yEnd: pts[attackIdx + 1].dy,
        curve: attackCurve,
      ));
    }

    // Decay segment: varies by curveType
    if (hasDecay) {
      int decayStartIdx;
      if (hasDelay && hasHold) {
        decayStartIdx = 3;
      } else if (hasDelay || hasHold) {
        decayStartIdx = 2;
      } else {
        decayStartIdx = 1;
      }
      if (decayStartIdx + 1 < pts.length) {
        // Decay end is the sustain node
        result.add(_SegmentCurve(
          param: 'decayCurve',
          xStart: pts[decayStartIdx].dx,
          xEnd: pts[decayStartIdx + 1].dx,
          yStart: pts[decayStartIdx].dy,
          yEnd: pts[decayStartIdx + 1].dy,
          curve: decayCurve,
        ));
      }
    }

    // Release segment: last boundary → end
    final relStartIdx = pts.length - 2;
    if (relStartIdx > 0 && relStartIdx + 1 < pts.length) {
      result.add(_SegmentCurve(
        param: 'releaseCurve',
        xStart: pts[relStartIdx].dx,
        xEnd: pts[relStartIdx + 1].dx,
        yStart: pts[relStartIdx].dy,
        yEnd: pts[relStartIdx + 1].dy,
        curve: releaseCurve,
      ));
    }

    return result;
  }
}
