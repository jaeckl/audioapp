import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';

part 'automation_curve_shapes_automation_shape_params.dart';

part 'automation_curve_shapes_automation_curve_shape_labels.dart';
part 'automation_curve_shapes_generate_automation_shape_points.dart';
part 'automation_curve_shapes_generate_saw.dart';
part 'automation_curve_shapes_generate_triangle.dart';
part 'automation_curve_shapes_generate_square.dart';
part 'automation_curve_shapes_generate_sine.dart';
part 'automation_curve_shapes_clamp_beat.dart';
part 'automation_curve_shapes_dedupe_points.dart';
part 'automation_curve_shapes_insert_automation_shape_between.dart';
part 'automation_curve_shapes_paint_repeated_automation_shape.dart';

/// Built-in automation envelope shapes (linear breakpoints for engine playback).
enum AutomationCurveShape {
  rampUp,
  rampDown,
  sawUp,
  sawDown,
  triangle,
  square,
  sine,
}

/// Parameters for [generateAutomationShapePoints].
/// Generate breakpoint list for an automation clip span.
/// Destructively replaces breakpoints between two anchors with [shape].
///
/// Points outside the span are kept. Anchor beats/values are preserved exactly.
/// Replaces a snapped region with one shape cycle per [stepBeats].
///
/// [baseline] and [peak] preserve drag polarity, so dragging downward
/// naturally inverts the selected shape without a separate command.
