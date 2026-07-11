import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../editor/clip_editor_transport.dart';
import '../editor/timeline_marker_layer.dart';
import '../play/play_deck.dart';
import '../play/play_deck_layout.dart';
import 'piano_roll_context_strip.dart';
import 'piano_roll_edit_sheet.dart';
import 'piano_roll_grid_sheet.dart';
import 'editor_view_range.dart';
import 'midi_lane_layout.dart';
import 'midi_comp_context_bar.dart';
import 'midi_comp_mode_hints.dart';
import 'midi_comp_tool.dart';
import 'midi_comp_tool_dock.dart';
import 'midi_take_comp_view.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_note_audition.dart';
import 'piano_roll_note_ops.dart';
import 'piano_roll_scale.dart';
import 'piano_roll_theme.dart';
import 'piano_roll_tool_dock.dart';
import 'piano_roll_viewport.dart';

part 'piano_roll_screen_private_piano_roll_screen_state.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_on_preview_transport_changed.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_start_preview_play.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_stop_preview_play.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_toggle_preview_play.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_app_bar_subtitle.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_push_undo.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_clone_notes.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_undo.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_redo.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_on_notes_changed.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_on_edit_started.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_on_edit_finished.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_apply_notes.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_queue_note_save.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_close_editor.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_quantize_selection.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_quantize_all.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_nudge_selected.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_delete_selected.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_persist_clip_length.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_ensure_comp_flattened.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_persist_notes.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_set_selected_midi_take_marker_mode.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_find_clip_in_snapshot.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_apply_refreshed_clip.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_flatten_midi_comp.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_reopen_midi_comp.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_with_midi_take_snapshot.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_take_region_index_at_beat.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_set_midi_take_at_beat.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_move_midi_take_marker.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_save_midi_take_marker_move.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_split_midi_take_at_playhead.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_delete_selected_midi_take_marker.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_nudge_selected_midi_take_marker.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_open_view_sheet.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_open_draw_sheet.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_on_scale_changed.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_persist_scale_settings.dart';
part 'piano_roll_screen_private_piano_roll_screen_state_open_edit_sheet.dart';

class PianoRollScreen extends StatefulWidget {
  const PianoRollScreen({
    super.key,
    required this.bridge,
    required this.clip,
    required this.trackName,
    required this.bpm,
    required this.onSnapshot,
    required this.savedArrangementPlayhead,
    this.drumAnchorPitch,
    this.drumLaneLayout,
  });

  final EngineBridge bridge;
  final MidiClipSnapshot clip;
  final String trackName;
  final int bpm;
  final ValueChanged<ProjectSnapshot> onSnapshot;
  final double savedArrangementPlayhead;

  /// GM drum pitch for this track (38 snare, 36 kick, …). Locks draw lane + scroll.
  final int? drumAnchorPitch;
  final MidiLaneLayout? drumLaneLayout;

  @override
  State<PianoRollScreen> createState() => _PianoRollScreenState();
}
