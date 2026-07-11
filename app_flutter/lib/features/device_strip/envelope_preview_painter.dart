import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'envelope_preview_painter_segment_curve.dart';
part 'envelope_preview_painter_envelope_preview_widget.dart';
part 'envelope_preview_painter_envelope_preview_widget_state.dart';

part 'envelope_preview_painter_is_sustain_node.dart';
part 'envelope_preview_painter_is_curvable_segment.dart';
part 'envelope_preview_painter_is_attack_segment.dart';
part 'envelope_preview_painter_is_release_segment.dart';
part 'envelope_preview_painter_draw_grid.dart';
part 'envelope_preview_painter_draw_curve.dart';
part 'envelope_preview_painter_draw_label.dart';

part 'envelope_preview_painter_compute_breakpoints.dart';
part 'envelope_preview_painter_curved_segments.dart';

const _analogAttackCurve = 0.85;
const _analogDecayCurve = 0.2;
const _analogReleaseCurve = 0.2;
const _adsr = 0;
const _asr = 1;
const _adr = 2;
const _ahdsr = 3;
const _samplesPerSegment = 20;

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

  /// Whether curvature handles are shown and adjustable.
  bool get _adjustableCurves => analogMode == 0;

  /// Effective curve value (analog overrides when mode is on).
  double _effectiveCurve(double userCurve, double analogFixed) =>
      analogMode != 0 ? analogFixed : userCurve;

  /// Compute breakpoint positions relative to [size].
  /// Used for both painting and hit-testing of boundary nodes.
  /// Returns the segment curve info for segments that have curvature.
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
  /// Whether the segment starting at [segStartIdx] is a curved segment.
  /// Whether the segment starting at [segStartIdx] is the attack segment.
  /// Whether the segment starting at [segStartIdx] is the release segment.
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
