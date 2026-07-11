import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../../bridge/timeline_clip.dart';
import '../editor/clip_editor_transport.dart';
import '../editor/timeline_marker_layer.dart';
import '../content_library/curve_library_dialog.dart';
import '../content_library/curve_library_store.dart';
import '../piano_roll/piano_roll_grid_sheet.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/editor_view_range.dart';
import 'automation_curve_shapes.dart';
import 'automation_editor_metrics.dart';
import 'automation_editor_theme.dart';
import 'automation_editor_tool_dock.dart';
import 'automation_editor_viewport.dart';
import 'automation_shape_panel.dart';

part 'automation_editor_screen_private_automation_editor_screen_state.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_on_preview_transport_changed.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_start_preview_play.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_stop_preview_play.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_toggle_preview_play.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_initial_points.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_clone_points.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_push_undo.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_undo.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_redo.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_clear_transient_selection.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_on_points_changed.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_on_tool_changed.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_select_shape_tool.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_toggle_select.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_toggle_delete_mark.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_open_insert_panel.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_close_insert_panel.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_apply_shape.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_on_shape_params_changed.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_delete_marked_nodes.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_persist_points.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_persist_clip_length.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_open_grid_sheet.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_save_curve_resource.dart';
part 'automation_editor_screen_private_automation_editor_screen_state_load_curve_resource.dart';

/// Full-screen automation clip editor — piano-roll layout with shape panel.
class AutomationEditorScreen extends StatefulWidget {
  const AutomationEditorScreen({
    super.key,
    required this.trackName,
    required this.clip,
    required this.bridge,
    required this.onSaved,
    required this.savedArrangementPlayhead,
    required this.bpm,
  });

  final String trackName;
  final AutomationClipSnapshot clip;
  final EngineBridge bridge;
  final ValueChanged<ProjectSnapshot> onSaved;
  final double savedArrangementPlayhead;
  final int bpm;

  @override
  State<AutomationEditorScreen> createState() => _AutomationEditorScreenState();
}
