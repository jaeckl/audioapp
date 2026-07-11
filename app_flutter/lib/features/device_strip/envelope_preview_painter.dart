import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'envelope_preview_painter_segment_curve.dart';
part 'envelope_preview_painter_envelope_preview_widget.dart';
part 'envelope_preview_painter_envelope_preview_widget_state.dart';

/// Easing function matching the C++ engine's `easeCurve`.
double easeCurve(double t, double curve) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  if (curve < 0.5) {
    // ease-in (concave): slow start
    final exp = 1.0 + 4.0 * (0.5 - curve);
    return math.pow(t, exp).toDouble();
  } else {
    // ease-out (convex): fast start
    final exp = 1.0 + 4.0 * (curve - 0.5);
    return 1.0 - math.pow(1.0 - t, exp).toDouble();
  }
}

/// Segment curvature info for a single envelope segment.
/// Paints a stylized envelope curve in the available space.
///
/// The envelope is drawn from left to right with segments:
/// Delay (flat 0), Attack (0→1 with curvature), Hold (1→1),
/// Decay (1→sustain with curvature), Sustain (sustain level),
/// Release (sustain→0 with curvature).
///
/// Each curved segment has a centered handle to adjust its curvature.
class EnvelopePreviewPainter extends CustomPainter {
  EnvelopePreviewPainter({
    required this.attack,
    required this.hold,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.curveType,
    this.delay = 0.0,
    this.attackCurve = 0.5,
    this.decayCurve = 0.5,
    this.releaseCurve = 0.5,
    this.analogMode = 0,
    this.accent = const Color(0xFFE8A54B),
    this.backgroundColor = const Color(0xFF1C1C26),
    this.padding = const EdgeInsets.fromLTRB(10, 8, 10, 20),
  });

  final double attack;
  final double hold;
  final double decay;
  final double sustain;
  final double release;
  final int curveType;
  final double delay;
  final double attackCurve;
  final double decayCurve;
  final double releaseCurve;
  final int analogMode;
  final Color accent;
  final Color backgroundColor;
  final EdgeInsets padding;

  // Analog-mode fixed curves (VCO-style RC charge/discharge)
  static const _analogAttackCurve = 0.85; // convex — fast initial rise
  static const _analogDecayCurve = 0.2; // concave — slow tail
  static const _analogReleaseCurve = 0.2; // concave — slow tail

  // Curve shapes
  static const _adsr = 0;
  static const _asr = 1;
  static const _adr = 2;
  static const _ahdsr = 3;

  static const _samplesPerSegment = 20;

  /// Whether curvature handles are shown and adjustable.
  bool get _adjustableCurves => analogMode == 0;

  /// Effective curve value (analog overrides when mode is on).
  double _effectiveCurve(double userCurve, double analogFixed) =>
      analogMode != 0 ? analogFixed : userCurve;

  /// Compute breakpoint positions relative to [size].
  /// Used for both painting and hit-testing of boundary nodes.
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

  /// Returns the segment curve info for segments that have curvature.
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

  /// Find the nearest interactive element (boundary or curvature handle).
  /// Returns (index, isCurvature) or (-1, false).
  ({int index, bool isCurvature}) nearestInteractive(Offset pos, Size size) {
    final pts = computeBreakpoints(size);
    const threshold = 30.0;

    // Check boundary nodes (skip first and last which are start/end)
    double minDist = threshold;
    int nearestBoundary = -1;
    for (var i = 1; i < pts.length - 1; i++) {
      final dist = (pts[i] - pos).distance;
      if (dist < minDist) {
        minDist = dist;
        nearestBoundary = i;
      }
    }

    // Check curvature handles (smaller threshold)
    final curves = curvedSegments(size);
    const curveThreshold = 28.0;
    double minCurveDist = curveThreshold;
    int nearestCurve = -1;
    for (var i = 0; i < curves.length; i++) {
      final handlePos = Offset(curves[i].midX, curves[i].curvedMidY);
      final dist = (handlePos - pos).distance;
      if (dist < minCurveDist) {
        minCurveDist = dist;
        nearestCurve = i;
      }
    }

    if (nearestBoundary >= 0 && minDist <= minCurveDist) {
      return (index: nearestBoundary, isCurvature: false);
    }
    if (nearestCurve >= 0) {
      return (index: nearestCurve, isCurvature: true);
    }
    return (index: -1, isCurvature: false);
  }

  /// Map a breakpoint index to the parameter it controls.
  /// Returns null for non-draggable points (start/end).
  static String? paramForNodeIndex(int index, int curveType) {
    final hasHold = curveType == _ahdsr;
    final hasDecay = curveType != _asr;
    final hasSustain = curveType != _adr;

    if (index <= 0) return null;

    final params = <String>['delay', 'attack'];
    if (hasHold) params.add('hold');
    if (hasDecay) params.add('decay');
    if (hasSustain) params.add('sustain');
    params.add('release');

    if (index >= params.length + 1) return null;
    return params[index - 1];
  }

  /// Returns true when the node at [index] sits on the sustain level
  /// (allowing vertical drag to adjust sustain).
  bool _isSustainNode(int index, List<Offset> pts) {
    if (index <= 0 || index >= pts.length - 1) return false;
    final dy = pts[index].dy;
    return dy > 2 && dy < pts[0].dy - 2;
  }

  /// Whether the segment starting at [segStartIdx] is a curved segment.
  bool _isCurvableSegment(int segStartIdx, List<Offset> pts, bool hasDelay,
      bool hasHold, bool hasDecay) {
    // Attack: first segment after delay (or the very first segment if no delay)
    // Decay: the segment ending at sustain level
    // Release: last segment
    // A segment is curvable if it's not flat (start y ≠ end y)
    if (segStartIdx + 1 >= pts.length) return false;
    if (pts[segStartIdx].dy == pts[segStartIdx + 1].dy) return false;

    // Skip flat hold segment (AHDSR)
    if (hasHold) {
      final holdIdx = (hasDelay ? 2 : 1);
      if (segStartIdx == holdIdx) return false; // hold is flat
    }
    // Skip sustain flat segment
    if (segStartIdx == pts.length - 2)
      return true; // release is always curvable
    if (segStartIdx >= 0 && segStartIdx < pts.length - 2)
      return true; // attack, decay, or other middle segment
    return false;
  }

  /// Whether the segment starting at [segStartIdx] is the attack segment.
  bool _isAttackSegment(int segStartIdx, List<Offset> pts, bool hasDelay) {
    final attackIdx = hasDelay ? 1 : 0;
    return segStartIdx == attackIdx;
  }

  /// Whether the segment starting at [segStartIdx] is the release segment.
  bool _isReleaseSegment(int segStartIdx, List<Offset> pts) {
    return segStartIdx == pts.length - 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    canvas.save();
    canvas.translate(padding.left, padding.top);
    final effectiveSize = Size(
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );
    _drawGrid(canvas, effectiveSize);
    _drawCurve(canvas, effectiveSize);
    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;

    for (final yFrac in [0.1, 0.5, 0.9]) {
      final y = size.height * (1.0 - yFrac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 1; i <= 3; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

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

  void _drawLabel(Canvas canvas, String text, double x, double bottom) {
    final builder = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: accent.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    builder.paint(canvas, Offset(x - builder.width / 2, bottom + 4));
  }

  @override
  bool shouldRepaint(EnvelopePreviewPainter oldDelegate) =>
      attack != oldDelegate.attack ||
      hold != oldDelegate.hold ||
      decay != oldDelegate.decay ||
      sustain != oldDelegate.sustain ||
      release != oldDelegate.release ||
      curveType != oldDelegate.curveType ||
      delay != oldDelegate.delay ||
      attackCurve != oldDelegate.attackCurve ||
      decayCurve != oldDelegate.decayCurve ||
      releaseCurve != oldDelegate.releaseCurve ||
      analogMode != oldDelegate.analogMode ||
      accent != oldDelegate.accent ||
      padding != oldDelegate.padding;
}

/// A tappable/draggable envelope preview widget.
///
/// Each breakpoint node can be dragged with a finger:
/// - Horizontal drag adjusts the associated time parameter.
/// - Vertical drag on sustain-level nodes adjusts the sustain level.
/// Each curved segment has a centered handle for adjusting curvature.
