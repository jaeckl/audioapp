import 'package:flutter/material.dart';

import '../piano_roll/piano_roll_metrics.dart';

part 'arrangement_loop_region_marker_arrangement_loop_region_line.dart';

part 'arrangement_loop_region_marker_arrangement_loop_region_pill.dart';
/// Baby-blue loop region markers (ruler pill + lane line).
abstract final class ArrangementLoopRegionTheme {
  static const Color color = Color(0xFF89CFF0);
  static const double pillSize = 14;
  static const double hitWidth = 20;
}
