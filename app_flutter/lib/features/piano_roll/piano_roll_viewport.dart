import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../bridge/project_snapshot.dart';
import '../editor/editor_virtual_playhead.dart';
import '../editor/timeline_marker_layer.dart';
import '../harmonic_assistant/harmonic_note_ops.dart';
import 'piano_roll_clip_end_marker.dart';
import 'piano_roll_grid_painter.dart';
import 'piano_roll_key_column.dart';
import 'editor_view_range.dart';
import 'piano_roll_metrics.dart';
import 'midi_lane_layout.dart';
import 'piano_roll_note_block.dart';
import 'piano_roll_ruler.dart';
import 'piano_roll_scale.dart';
import 'piano_roll_theme.dart';
import '../harmonic_assistant/harmonic_roll_plus_button.dart';

part 'piano_roll_viewport_private_drag_mode.dart';
part 'piano_roll_viewport_private_pinch_zoom_axis.dart';
part 'piano_roll_viewport_piano_roll_viewport_state.dart';
part 'piano_roll_viewport_private_piano_roll_scroll_behavior.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_top_for_pitch.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_marker_overlay_scroll.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_reveal_playhead_at_viewport_origin.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_schedule_apply_view_range.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_apply_view_range.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_jump_scroll_to_start.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_update_scroll_viewport_width.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_pointer_to_canvas.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_hit_clip_end_marker.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_clamp_clip_length.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_canvas_pointer_span_x.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_canvas_pointer_span_y.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_resolve_pinch_axis.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_canvas_focal_point.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_ruler_pointer_down.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_ruler_pointer_move.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_ruler_pointer_up.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_canvas_pointer_down.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_canvas_pointer_move.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_on_canvas_pointer_up.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_cancel_edit_gesture.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_end_edit_gesture.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_begin_draw_at.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_update_draw.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_insert_note_at.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_apply_note_drag.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_apply_horizontal_pinch_zoom.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_apply_vertical_pinch_zoom.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_link_scroll.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_emit_center_octave.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_schedule_initial_scroll.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_pitch_from_dy.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_beat_from_dx.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_note_index_at.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_drag_mode_at.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_chord_group.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_set_notes.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_delete_note.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_update_note.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_build_synced_marker_stack_layers.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_build_note_canvas.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_build_note_canvas_viewport.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_build_key_column.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_build_timeline_ruler_band.dart';
part 'piano_roll_viewport_piano_roll_viewport_state_build_timeline_canvas_band.dart';

class PianoRollViewport extends StatefulWidget {
  const PianoRollViewport({
    super.key,
    required this.notes,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.minPitch,
    required this.maxPitch,
    this.drumAnchorPitch,
    this.laneLayout,
    required this.gridSettings,
    required this.scaleSettings,
    required this.tool,
    this.drawPattern = PianoRollDrawPattern.single,
    required this.selectedIndex,
    required this.onNotesChanged,
    required this.onSelectionChanged,
    required this.onEditStarted,
    required this.onEditFinished,
    this.onCenterOctaveChanged,
    this.onClipLengthChanged,
    this.onClipLengthCommit,
    this.viewRangeBars = EditorViewRange.defaultBars,
    this.virtualPlayheadBeat,
    this.onVirtualPlayheadSeek,
    this.onVirtualPlayheadTap,
    this.previewPlaying = false,
    this.onPreviewPlayRequested,
    this.onPreviewStopRequested,
    this.onNotePreview,
    this.onNotePreviewEnd,
    this.onPitchPreview,
    this.selectedPitch,
    this.timelineScrollController,
    this.chordGroupEdit = false,
    this.chordGroupSelected = true,
    this.onChordGroupSelectedChanged,
    this.onHarmonyInsertTap,
    this.harmonyInsertTooltip = 'Insert after last chord',
    this.chordSlots = const [],
    this.onChordSlotsChanged,
  });

  final List<MidiNoteSnapshot> notes;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final int minPitch;
  final int maxPitch;
  final int? drumAnchorPitch;
  final MidiLaneLayout? laneLayout;
  final PianoRollGridSettings gridSettings;
  final PianoRollScaleSettings scaleSettings;
  final PianoRollTool tool;
  final PianoRollDrawPattern drawPattern;
  final int? selectedIndex;
  final ValueChanged<List<MidiNoteSnapshot>> onNotesChanged;
  final ValueChanged<int?> onSelectionChanged;
  final VoidCallback onEditStarted;
  final VoidCallback onEditFinished;
  final ValueChanged<int>? onCenterOctaveChanged;
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
  final void Function(MidiNoteSnapshot note, {bool hold})? onNotePreview;
  final VoidCallback? onNotePreviewEnd;
  final ValueChanged<int>? onPitchPreview;

  /// Selected drum lane pitch (drums mode). Highlighted in the key column.
  final int? selectedPitch;

  /// Harmonic/Progression: tap selects chord cluster; double-tap drills to note.
  final bool chordGroupEdit;

  /// When [chordGroupEdit], true = whole chord; false = single drilled note.
  final bool chordGroupSelected;

  final ValueChanged<bool>? onChordGroupSelectedChanged;

  /// When set, shows a + at the start of empty timeline after last chord.
  final VoidCallback? onHarmonyInsertTap;
  final String harmonyInsertTooltip;

  /// Stable chord spans for Harmonic/Progression/Rhythm group edit.
  final List<ChordSlot> chordSlots;
  final ValueChanged<List<ChordSlot>>? onChordSlotsChanged;

  @override
  State<PianoRollViewport> createState() => PianoRollViewportState();
}

/// Suppresses Android accent overscroll flash when the pen tool locks scrolling.
