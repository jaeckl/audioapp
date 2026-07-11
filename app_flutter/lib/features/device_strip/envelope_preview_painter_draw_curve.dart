part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterDrawcurve on EnvelopePreviewPainter {
  void _drawCurve(Canvas canvas, Size size) {
    final pts = computeBreakpoints(size);
    final hPx = size.height;
    final hasDelay = delay > 0.01;

    final curvePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);

    final hasHold = curveType == _ahdsr;
    final hasDecay = curveType != _asr;

    for (var i = 0; i < pts.length - 1; i++) {
      final x0 = pts[i].dx;
      final y0 = pts[i].dy;
      final x1 = pts[i + 1].dx;
      final y1 = pts[i + 1].dy;

      // Determine if this segment is attack, decay, or release (curvable)
      final isCurbable =
          _isCurvableSegment(i, pts, hasDelay, hasHold, hasDecay);

      if (isCurbable && y0 != y1) {
        // Curved segment — sample with effective curve
        final double curve;
        if (_isAttackSegment(i, pts, hasDelay)) {
          curve = _effectiveCurve(attackCurve, _analogAttackCurve);
        } else if (_isReleaseSegment(i, pts)) {
          curve = _effectiveCurve(releaseCurve, _analogReleaseCurve);
        } else {
          curve = _effectiveCurve(decayCurve, _analogDecayCurve);
        }
        final rising = y1 < y0;
        for (var s = 1; s <= _samplesPerSegment; s++) {
          final t = s / _samplesPerSegment;
          final eased = easeCurve(t, curve);
          final x = x0 + (x1 - x0) * t;
          final y = rising ? y0 - (y0 - y1) * eased : y0 + (y1 - y0) * eased;
          path.lineTo(x, y);
        }
      } else {
        // Straight segment (delay, hold, sustain)
        path.lineTo(x1, y1);
      }
    }

    canvas.drawPath(path, curvePaint);

    // Draw boundary nodes
    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    for (final pt in pts) {
      canvas.drawCircle(pt, 4.0, dotPaint);
    }

    // Draw curvature handles (only in digital/adjustable mode)
    if (_adjustableCurves) {
      final curves = curvedSegments(size);
      for (final seg in curves) {
        final handlePos = Offset(seg.midX, seg.curvedMidY);
        canvas.drawCircle(
          handlePos,
          5.0,
          Paint()
            ..color = accent.withValues(alpha: 0.5)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          handlePos,
          5.0,
          Paint()
            ..color = accent.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Add labels under the curve
    final hasSustain = curveType != _adr;

    if (hasDelay) {
      _drawLabel(canvas, 'Dl', pts.length > 1 ? pts[1].dx : 0, hPx);
    }
    final aIdx = hasDelay ? 2 : 1;
    _drawLabel(canvas, 'A', aIdx < pts.length ? pts[aIdx].dx : 0, hPx);
    if (hasHold) {
      final hIdx = hasDelay ? 3 : 2;
      _drawLabel(canvas, 'H', hIdx < pts.length ? pts[hIdx].dx : 0, hPx);
    }
    if (hasDecay) {
      final decayIdx = hasDelay ? (hasHold ? 4 : 3) : (hasHold ? 3 : 2);
      _drawLabel(
          canvas, 'D', decayIdx < pts.length ? pts[decayIdx].dx : 0, hPx);
    }
    if (hasSustain) {
      final susIdx = hasDelay
          ? (hasHold ? (hasDecay ? 5 : 4) : (hasDecay ? 4 : 3))
          : (hasHold ? (hasDecay ? 4 : 3) : (hasDecay ? 3 : 2));
      _drawLabel(canvas, 'S', susIdx < pts.length ? pts[susIdx].dx : 0, hPx);
    }
    final relIdx = pts.length - 2;
    _drawLabel(canvas, 'R', relIdx > 0 ? pts[relIdx].dx : 0, hPx);
  }
}
