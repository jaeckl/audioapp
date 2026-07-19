import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../bridge/project_snapshot.dart';
import '../clip_drag/sample_clip_drag_data.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_ruler.dart';
import '../piano_roll/piano_roll_theme.dart';
import 'arrangement_clip_drag.dart';
import 'arrangement_clip_theme.dart';
import 'arrangement_grid_painter.dart';
import 'arrangement_loop_region_marker.dart';
import 'arrangement_playhead_marker.dart';
import 'arrangement_playhead_overlay.dart';
import 'arrangement_theme.dart';
import 'arrangement_timeline_metrics.dart';
import '../editor/timeline_marker_layer.dart';
import 'automation_clip_renderer.dart';
import 'clip_renderer.dart';
import 'freeze_clip_renderer.dart';
import 'midi_clip_renderer.dart';
import 'sample_clip_renderer.dart';
import 'snap_grid_resolution.dart';
import 'track_lane_icon.dart';
import 'track_mix_button.dart';

part 'arrangement_view_private_ruler_drag_target.dart';
part 'arrangement_view_private_track_drop_zone.dart';
part 'arrangement_view_private_track_drag_data.dart';
part 'arrangement_view_private_track_drop_intent.dart';
part 'arrangement_view_arrangement_view_state.dart';
part 'arrangement_view_private_master_header.dart';
part 'arrangement_view_private_master_lane.dart';
part 'arrangement_view_private_track_drop_target.dart';
part 'arrangement_view_private_track_drop_target_state.dart';
part 'arrangement_view_private_track_drag_feedback.dart';
part 'arrangement_view_private_track_header.dart';
part 'arrangement_view_private_add_track_header.dart';
part 'arrangement_view_private_add_track_lane.dart';
part 'arrangement_view_private_resize_clip_ref.dart';
part 'arrangement_view_private_track_lane.dart';
part 'arrangement_view_private_automation_clip_block.dart';
part 'arrangement_view_private_midi_clip_block.dart';
part 'arrangement_view_private_freeze_clip_block.dart';
part 'arrangement_view_private_sample_clip_block.dart';
part 'arrangement_view_private_sample_clip_block_state.dart';
part 'arrangement_view_private_clip_drag_preview.dart';
part 'arrangement_view_private_clip_resize_session.dart';
part 'arrangement_view_private_clip_resize_handle.dart';
part 'arrangement_view_private_clip_resize_handle_state.dart';
part 'arrangement_view_arrangement_view_state_ruler_canvas_dx.dart';
part 'arrangement_view_arrangement_view_state_beat_from_ruler_canvas_dx.dart';
part 'arrangement_view_arrangement_view_state_hit_region_marker.dart';
part 'arrangement_view_arrangement_view_state_hit_playhead_marker.dart';
part 'arrangement_view_arrangement_view_state_on_ruler_pointer_down.dart';
part 'arrangement_view_arrangement_view_state_on_ruler_pointer_move.dart';
part 'arrangement_view_arrangement_view_state_on_ruler_pointer_up.dart';
part 'arrangement_view_arrangement_view_state_on_playhead_hit_pointer_down.dart';
part 'arrangement_view_arrangement_view_state_on_playhead_hit_pointer_move.dart';
part 'arrangement_view_arrangement_view_state_on_playhead_hit_pointer_up.dart';
part 'arrangement_view_arrangement_view_state_on_playhead_listenable_tick.dart';
part 'arrangement_view_arrangement_view_state_bind_timeline_scroll_controller.dart';
part 'arrangement_view_arrangement_view_state_schedule_playback_follow_state_change.dart';
part 'arrangement_view_arrangement_view_state_schedule_playback_follow_update.dart';
part 'arrangement_view_arrangement_view_state_reveal_playhead_at_viewport_origin.dart';
part 'arrangement_view_arrangement_view_state_catch_up_playhead_on_play.dart';
part 'arrangement_view_arrangement_view_state_follow_playhead_if_needed.dart';
part 'arrangement_view_arrangement_view_state_playhead_visible_at_playback_start.dart';
part 'arrangement_view_arrangement_view_state_jump_scroll_to_beat.dart';
part 'arrangement_view_arrangement_view_state_end_programmatic_scroll.dart';
part 'arrangement_view_arrangement_view_state_animate_scroll_to_beat.dart';
part 'arrangement_view_arrangement_view_state_cancel_follow_scroll.dart';
part 'arrangement_view_arrangement_view_state_resume_follow.dart';
part 'arrangement_view_arrangement_view_state_suspend_follow.dart';
part 'arrangement_view_arrangement_view_state_notify_follow_suspended.dart';
part 'arrangement_view_arrangement_view_state_notify_follow_resumed.dart';
part 'arrangement_view_arrangement_view_state_on_timeline_scroll.dart';
part 'arrangement_view_arrangement_view_state_sync_track_scroll_to_master.dart';
part 'arrangement_view_arrangement_view_state_sync_master_scroll_to_track.dart';
part 'arrangement_view_arrangement_view_state_sync_track_vertical_to_header.dart';
part 'arrangement_view_arrangement_view_state_sync_header_vertical_to_track.dart';
part 'arrangement_view_arrangement_view_state_on_pointer_down.dart';
part 'arrangement_view_arrangement_view_state_on_pointer_up.dart';
part 'arrangement_view_arrangement_view_state_on_scale_start.dart';
part 'arrangement_view_arrangement_view_state_on_scale_update.dart';
part 'arrangement_view_arrangement_view_state_beat_from_global.dart';
part 'arrangement_view_arrangement_view_state_placement_for_track.dart';
part 'arrangement_view_arrangement_view_state_source_track_index.dart';
part 'arrangement_view_arrangement_view_state_track_index_from_global.dart';
part 'arrangement_view_arrangement_view_state_desired_beat_for_drag.dart';
part 'arrangement_view_arrangement_view_state_preview_start_beat_for_track.dart';
part 'arrangement_view_arrangement_view_state_start_clip_drag.dart';
part 'arrangement_view_arrangement_view_state_update_clip_drag.dart';
part 'arrangement_view_arrangement_view_state_update_clip_drag_at.dart';
part 'arrangement_view_arrangement_view_state_on_clip_drag_end.dart';
part 'arrangement_view_arrangement_view_state_on_sample_clip_drag_end.dart';
part 'arrangement_view_arrangement_view_state_end_clip_drag.dart';
part 'arrangement_view_arrangement_view_state_cancel_clip_drag.dart';
part 'arrangement_view_arrangement_view_state_resize_min_length_for_kind.dart';
part 'arrangement_view_arrangement_view_state_compute_preview_length_beats.dart';
part 'arrangement_view_arrangement_view_state_start_clip_resize.dart';
part 'arrangement_view_arrangement_view_state_update_clip_resize.dart';
part 'arrangement_view_arrangement_view_state_end_clip_resize.dart';
part 'arrangement_view_arrangement_view_state_cancel_clip_resize.dart';
part 'arrangement_view_arrangement_view_state_maybe_resolve_pending_resize.dart';
part 'arrangement_view_arrangement_view_state_length_beats_for_clip.dart';
part 'arrangement_view_arrangement_view_state_clip_kind_for_resize.dart';
part 'arrangement_view_arrangement_view_state_preview_length_for.dart';
part 'arrangement_view_arrangement_view_state_on_track_long_press.dart';
part 'arrangement_view_arrangement_view_state_show_track_popup_menu.dart';
part 'arrangement_view_arrangement_view_state_show_add_track_menu.dart';
part 'arrangement_view_arrangement_view_state_visible_tracks.dart';
part 'arrangement_view_arrangement_view_state_track_snapshot_by_id.dart';
part 'arrangement_view_arrangement_view_state_next_track_id_in_scope.dart';
part 'arrangement_view_arrangement_view_state_track_drop_intent.dart';
part 'arrangement_view_arrangement_view_state_commit_track_drop.dart';
part 'arrangement_view_arrangement_view_state_on_track_header_tap.dart';
part 'arrangement_view_arrangement_view_state_auto_scroll_track_drag.dart';
part 'arrangement_view_arrangement_view_state_clip_loop_content.dart';
part 'arrangement_view_arrangement_view_state_show_clip_menu.dart';
part 'arrangement_view_arrangement_view_state_build_content.dart';
part 'arrangement_view_arrangement_view_state_build_stack.dart';

// Clip edge interaction. The hit target remains comfortably touchable while
// the visible rail stays subordinate to the clip content. For clips narrower
// than the normal target, the target shrinks to the rendered clip width so its
// right edge never floats beyond the clip.
const double kResizeHandleVisualWidth = 4.0;
const double kResizeHandleHitWidth = 44.0;
const double _kAutomationMinLengthBeats = 0.01;

class ArrangementView extends StatefulWidget {
  const ArrangementView({
    super.key,
    required this.snapshot,
    required this.onTrackSelected,
    required this.onAddTrack,
    this.onAddGroup,
    this.onSetTrackGroup,
    this.onMoveTrack,
    this.onSetTrackMuted,
    this.onSetTrackSoloed,
    this.onSetTrackRecordArmed,
    this.onToggleTrackFreeze,
    required this.onAddMidiClip,
    required this.onAddAudioClip,
    required this.playheadBeats,
    required this.playing,
    required this.onPlayRequested,
    required this.onStopRequested,
    required this.onPlayheadSeek,
    required this.onLoopRegionChanged,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onMoveClip,
    this.onDeleteTrack,
    this.onDeleteClip,
    this.onDuplicateClip,
    this.onSetClipLoopContent,
    this.onAddAutomationClip,
    this.automationLinkClipId,
    this.highlightedClipId,
    this.onAutomationLinkToggle,
    this.onAutomationClipDoubleTap,
    this.focusTrackId,
    this.compact = false,
    this.timelineScrollController,
    this.followPlayheadEnabled = true,
    this.onFollowSuspended,
    this.onFollowResumed,
    this.playheadListenable,
    this.liveClipStartBeats = const {},
    this.liveMidiPreviewNotes = const {},
    this.liveMidiPreviewClips = const {},
    this.onResizeClipCommit,
    this.snapClipsEnabled = true,
    this.snapGridResolution = SnapGridResolution.adaptive,
    this.snapGridTriplet = false,
  });

  final ProjectSnapshot snapshot;
  final SnapGridResolution snapGridResolution;
  final bool snapGridTriplet;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final VoidCallback? onAddGroup;
  final Future<void> Function(String trackId, String? groupTrackId)?
      onSetTrackGroup;
  final Future<void> Function({
    required String trackId,
    required String parentGroupId,
    required String beforeTrackId,
  })? onMoveTrack;
  final Future<void> Function({
    required String trackId,
    required bool muted,
  })? onSetTrackMuted;
  final Future<void> Function({
    required String trackId,
    required bool soloed,
  })? onSetTrackSoloed;
  final Future<void> Function({
    required String trackId,
    required bool armed,
  })? onSetTrackRecordArmed;
  final Future<void> Function({
    required String trackId,
    required bool enabled,
    required bool stale,
  })? onToggleTrackFreeze;
  final void Function(String trackId, double startBeat) onAddMidiClip;
  final void Function(String trackId, double desiredStartBeat) onAddAudioClip;
  final double playheadBeats;
  final bool playing;
  final VoidCallback onPlayRequested;
  final VoidCallback onStopRequested;
  final ValueChanged<double> onPlayheadSeek;
  final Future<void> Function({
    required double startBeat,
    required double endBeat,
  }) onLoopRegionChanged;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final Future<void> Function({
    required String clipId,
    required String trackId,
    required double startBeat,
  }) onMoveClip;
  final void Function(String trackId)? onDeleteTrack;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onDuplicateClip;
  final Future<void> Function({
    required String clipId,
    required bool loopContent,
  })? onSetClipLoopContent;
  final void Function(String trackId, double startBeat)? onAddAutomationClip;
  final String? automationLinkClipId;
  final String? highlightedClipId;
  final void Function(String clipId)? onAutomationLinkToggle;
  final void Function(String trackId, AutomationClipSnapshot clip)?
      onAutomationClipDoubleTap;

  /// When [compact] is true, only this track lane is shown (defaults to selected).
  final String? focusTrackId;

  /// Hides master/add-track chrome for embedded play-mode timeline.
  final bool compact;
  final TimelineViewportScrollController? timelineScrollController;
  final bool followPlayheadEnabled;
  final VoidCallback? onFollowSuspended;
  final VoidCallback? onFollowResumed;

  /// When set, playhead marker layers listen here instead of rebuilding this widget each tick.
  final ValueListenable<double>? playheadListenable;
  final Map<String, double> liveClipStartBeats;
  final Map<String, List<MidiNoteSnapshot>> liveMidiPreviewNotes;
  final Map<String, List<MidiClipSnapshot>> liveMidiPreviewClips;

  /// Called when the user finishes dragging a clip's right-edge resize handle.
  /// Receives the final preview length in beats; bridge dispatch happens outside.
  final Future<void> Function({
    required String clipId,
    required double lengthBeats,
  })? onResizeClipCommit;
  final bool snapClipsEnabled;

  @override
  State<ArrangementView> createState() => ArrangementViewState();
}

/// Lightweight reference used by [_TrackLane.build] to enumerate every clip
/// on the track when laying out resize handles. Avoids dragging the concrete
/// clip-snapshot type through the resize-handle loop.
// ────────────────────────────────────────────────────────────────────────────
// Clip resize — session + handle widget (WP-1)
// ────────────────────────────────────────────────────────────────────────────

/// Private session for an in-progress clip resize drag. Mutable so the
/// pointer-move path can update [previewLengthBeats] without reallocating.
///
/// Lifecycle:
///   1. active drag → previewLengthBeats live
///   2. gesture ends → session kept around (committed) so the resize handle
///      still shows at the preview position until the engine snapshot refreshes
///   3. parent re-renders with the new length → session drops in didUpdateWidget
/// Private visual + gesture handle for the right edge of clip blocks.
/// Sits as the last child of the clip-block Stack so it receives pointer
/// events before the clip body's drag detector. The parent (_TrackLane)
/// pre-computes [adjacentClipStartBeat] for this clip and binds it into
/// [onResizeStart]; this widget does not track track-level layout itself.
///
/// The visual mirrors the sampler trim handle — a 12 px bar with rounded
/// corners on the outer (right) side, a `drag_handle` icon centered, and a
/// subtle drop shadow + dark border so it stands off the clip body. The
/// touch target is wider than the visual bar (28 px) for forgiving pickup.
