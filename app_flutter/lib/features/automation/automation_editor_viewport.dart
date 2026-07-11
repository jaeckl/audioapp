import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/project_snapshot.dart';
import '../editor/editor_virtual_playhead.dart';
import '../editor/timeline_marker_layer.dart';
import '../piano_roll/piano_roll_clip_end_marker.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_ruler.dart';
import '../piano_roll/piano_roll_theme.dart';
import '../piano_roll/editor_view_range.dart';
import 'automation_curve_grid_painter.dart';
import 'automation_curve_shapes.dart';
import 'automation_editor_metrics.dart';
import 'automation_value_column.dart';

part 'automation_editor_viewport_private_pinch_zoom_axis.dart';
part 'automation_editor_viewport_automation_editor_viewport_state.dart';
part 'automation_editor_viewport_private_automation_scroll_behavior.dart';

part 'automation_editor_viewport_automation_editor_viewport_state_on_marker_overlay_scroll.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_reveal_playhead_at_viewport_origin.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_schedule_apply_view_range.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_apply_view_range.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_jump_scroll_to_start.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_update_scroll_viewport_width.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_link_scroll.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_ensure_value_axis_height.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_pointer_to_canvas.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_beat_from_dx.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_update_shape_paint.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_update_freehand.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_hit_clip_end_marker.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_clamp_clip_length.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_hit_test_point.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_sorted_points.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_cancel_edit_gesture.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_canvas_pointer_span_x.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_canvas_pointer_span_y.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_resolve_pinch_axis.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_canvas_focal_point.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_apply_horizontal_pinch_zoom.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_apply_vertical_pinch_zoom.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_on_ruler_pointer_down.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_on_ruler_pointer_move.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_on_ruler_pointer_up.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_on_canvas_pointer_down.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_on_canvas_pointer_move.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_on_canvas_pointer_up.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_build_synced_marker_stack_layers.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_build_value_column.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_build_timeline_ruler_band.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_build_timeline_canvas_band.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_build_canvas.dart';
part 'automation_editor_viewport_automation_editor_viewport_state_build_canvas_viewport.dart';

const double _tapSlop = 8;
const double _pinchMinSpan = 8;
const double _pinchAxisRatio = 1.15;

class AutomationEditorViewport extends StatefulWidget {
  const AutomationEditorViewport({
    super.key,
    required this.points,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.gridSettings,
    required this.tool,
    this.paintShape,
    required this.selectedIndices,
    required this.deleteMarkedIndices,
    this.insertHighlightStartBeat,
    this.insertHighlightEndBeat,
    required this.onPointsChanged,
    required this.onToggleSelect,
    required this.onToggleDeleteMark,
    required this.onClearSelection,
    required this.onEditStarted,
    required this.onEditFinished,
    this.onClipLengthChanged,
    this.onClipLengthCommit,
    this.viewRangeBars = EditorViewRange.defaultBars,
    this.virtualPlayheadBeat,
    this.onVirtualPlayheadSeek,
    this.onVirtualPlayheadTap,
    this.previewPlaying = false,
    this.onPreviewPlayRequested,
    this.onPreviewStopRequested,
    this.timelineScrollController,
  });

  final List<AutomationPointSnapshot> points;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final PianoRollGridSettings gridSettings;
  final AutomationEditorTool tool;
  final AutomationCurveShape? paintShape;
  final Set<int> selectedIndices;
  final Set<int> deleteMarkedIndices;
  final double? insertHighlightStartBeat;
  final double? insertHighlightEndBeat;
  final ValueChanged<List<AutomationPointSnapshot>> onPointsChanged;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<int> onToggleDeleteMark;
  final VoidCallback onClearSelection;
  final VoidCallback onEditStarted;
  final VoidCallback onEditFinished;
  final ValueChanged<double>? onClipLengthChanged;
  final VoidCallback? onClipLengthCommit;
  final int viewRangeBars;
  final double? virtualPlayheadBeat;
  final ValueChanged<double>? onVirtualPlayheadSeek;
  final VoidCallback? onVirtualPlayheadTap;
  final bool previewPlaying;
  final VoidCallback? onPreviewPlayRequested;
  final VoidCallback? onPreviewStopRequested;
  final TimelineViewportScrollController? timelineScrollController;

  @override
  State<AutomationEditorViewport> createState() =>
      AutomationEditorViewportState();
}
