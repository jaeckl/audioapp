import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../automation/automation_curve_shapes.dart';
import '../automation/automation_shape_icon.dart';
import '../content_library/curve_library_dialog.dart';
import '../content_library/curve_library_store.dart';

part 'curve_editor_screen_curve_editor_tool.dart';
part 'curve_editor_screen_private_curve_editor_screen_state.dart';
part 'curve_editor_screen_private_shape_insert_sheet.dart';
part 'curve_editor_screen_private_shape_insert_sheet_state.dart';
part 'curve_editor_screen_private_curve_editor_painter.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_import_mod.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_collect_updates.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_sync_to_bridge.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_merge_sort.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_hit_test_point.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_start_shape_paint.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_update_shape_paint.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_end_shape_paint.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_toggle_select.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_clear_selection.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_generate_segment_shape.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_insert_shape_between.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_open_shape_sheet.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_pan_start.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_pan_update.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_pan_end.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_select_drag.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_select_tap.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_draw_start.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_draw_update.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_draw_end.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_rebuild_from_draw.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_tap_up.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_on_erase_tap.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_reset_to_default.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_save_curve_resource.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_load_curve_resource.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_build_toolbar.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_tool_btn.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_shape_btn.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_icon_btn.dart';
part 'curve_editor_screen_private_curve_editor_screen_state_polarity_toggle.dart';

/// Tool modes for the curve editor canvas.
const double _hitRadius = 22.0;
const double _dotRadius = 6.0;
const double _selectedDotRadius = 9.0;
const Color _accent = Color(0xFFE8A54B);
const int _gridDivisions = 8;

/// Fullscreen curve modulator editor with automation-style tool system.
class CurveEditorScreen extends StatefulWidget {
  const CurveEditorScreen({
    super.key,
    required this.mod,
    required this.onUpdate,
    required this.onBatchUpdate,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;
  final Future<void> Function(List<Map<String, dynamic>> params) onBatchUpdate;

  @override
  State<CurveEditorScreen> createState() => _CurveEditorScreenState();
}

// =============================================================================
//  Shape insert bottom sheet
// =============================================================================

// =============================================================================
//  _CurveEditorPainter
// =============================================================================
