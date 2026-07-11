import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../automation/automation_editor_theme.dart';
import '../arrangement/arrangement_loop_region_marker.dart';
import '../arrangement/snap_grid_resolution.dart';
import '../editor/clip_editor_transport.dart';
import '../editor/editor_virtual_playhead.dart';
import '../device_strip/rotary_knob.dart';
import 'editable_waveform.dart';
import 'sample_editor_snap.dart';
import 'sample_editor_snap_sheet.dart';
import 'sample_editor_take_panel.dart';

part 'sample_editor_screen_private_sample_tool.dart';
part 'sample_editor_screen_private_sample_menu_action.dart';
part 'sample_editor_screen_private_slice_auto_mode.dart';
part 'sample_editor_screen_private_slice_tab.dart';
part 'sample_editor_screen_private_fade_curve_kind.dart';
part 'sample_editor_screen_private_sample_editor_screen_state.dart';
part 'sample_editor_screen_private_sample_timeline.dart';
part 'sample_editor_screen_private_sample_timeline_state.dart';
part 'sample_editor_screen_private_raw_pinch_zoom.dart';
part 'sample_editor_screen_private_raw_pinch_zoom_state.dart';
part 'sample_editor_screen_private_sample_ruler_painter.dart';
part 'sample_editor_screen_private_sample_lane_painter.dart';
part 'sample_editor_screen_private_tool_button.dart';
part 'sample_editor_screen_private_sample_tool_card.dart';
part 'sample_editor_screen_private_tool_card_header.dart';
part 'sample_editor_screen_private_clip_edit_panel.dart';
part 'sample_editor_screen_private_fade_curve_selector.dart';
part 'sample_editor_screen_private_fade_curve_icon_button.dart';
part 'sample_editor_screen_private_fade_curve_icon_painter.dart';
part 'sample_editor_screen_private_inline_readout.dart';
part 'sample_editor_screen_private_process_panel.dart';
part 'sample_editor_screen_private_process_tab.dart';
part 'sample_editor_screen_private_process_panel_state.dart';
part 'sample_editor_screen_private_process_tab_bar.dart';
part 'sample_editor_screen_private_process_tab_chip.dart';
part 'sample_editor_screen_private_slice_panel.dart';
part 'sample_editor_screen_private_slice_panel_state.dart';
part 'sample_editor_screen_private_slice_tab_bar.dart';
part 'sample_editor_screen_private_slice_tab_button.dart';
part 'sample_editor_screen_private_slice_choice_chip.dart';
part 'sample_editor_screen_private_slice_slider_row.dart';
part 'sample_editor_screen_private_slice_command_button.dart';
part 'sample_editor_screen_private_slice_icon_button.dart';
part 'sample_editor_screen_private_process_group.dart';
part 'sample_editor_screen_private_mini_toggle.dart';
part 'sample_editor_screen_private_engine_field.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_sync_preview_transport_span.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_transport_changed.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_schedule_save.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_save.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_normalize.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_audition.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_toggle_loop.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_toggle_warp.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_save_slices.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_sanitize_markers.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_toggle_slice.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_select_slice_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_move_slice.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_delete_selected_slice_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_nudge_selected_slice_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_audition_selected_slice_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_audition_slice.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_detect_transient_markers.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_even_slice_markers.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_grid_slice_markers.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_auto_slice.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_reset_slices.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_export_slices.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_take_region_index_at_beat.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_set_take_at_beat.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_select_take_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_move_take_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_save_take_marker_move.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_delete_selected_take_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_nudge_selected_take_marker.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_split_take_at_playhead.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_find_clip_in_snapshot.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_open_snap_settings.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_snap_source.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_handle_menu_action.dart';
part 'sample_editor_screen_private_sample_editor_screen_state_build_content.dart';
part 'sample_editor_screen_private_sample_timeline_state_usable_source_width.dart';
part 'sample_editor_screen_private_sample_timeline_state_source_from_playhead_beat.dart';
part 'sample_editor_screen_private_sample_timeline_state_playhead_beat_from_source.dart';
part 'sample_editor_screen_private_sample_timeline_state_playhead_x.dart';
part 'sample_editor_screen_private_sample_timeline_state_build_content.dart';
extension _FadeCurveKindX on _FadeCurveKind {
  double get value => switch (this) {
        _FadeCurveKind.linear => 0.0,
        _FadeCurveKind.quadratic => 0.33,
        _FadeCurveKind.cubic => 0.66,
        _FadeCurveKind.smooth => 1.0,
      };

  static _FadeCurveKind fromValue(double value) {
    var closest = _FadeCurveKind.linear;
    var distance = (value - closest.value).abs();
    for (final kind in _FadeCurveKind.values.skip(1)) {
      final next = (value - kind.value).abs();
      if (next < distance) {
        closest = kind;
        distance = next;
      }
    }
    return closest;
  }
}

class SampleEditorScreen extends StatefulWidget {
  const SampleEditorScreen(
      {super.key,
      required this.bridge,
      required this.clip,
      required this.trackName,
      required this.samples,
      required this.onSnapshot,
      required this.bpm,
      required this.savedArrangementPlayhead});
  final EngineBridge bridge;
  final SampleClipSnapshot clip;
  final String trackName;
  final List<SampleLibraryEntrySnapshot> samples;
  final Future<void> Function(ProjectSnapshot snapshot) onSnapshot;
  final int bpm;
  final double savedArrangementPlayhead;

  @override
  State<SampleEditorScreen> createState() => _SampleEditorScreenState();
}

String _midiNoteName(int note) {
  const names = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B'
  ];
  return '${names[note % 12]}${note ~/ 12 - 1}';
}
