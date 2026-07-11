import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/arrangement_loop_region_marker.dart';
import '../editor/editor_beat_tap.dart';
import '../editor/editor_pinch_zoom.dart';
import '../editor/editor_virtual_playhead.dart';
import 'editor_view_range.dart';
import 'midi_comp_tool.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_ruler.dart';
import 'piano_roll_theme.dart';

part 'midi_take_comp_view_private_midi_take_comp_view_state.dart';
part 'midi_take_comp_view_private_midi_take_label_rail.dart';
part 'midi_take_comp_view_private_midi_take_lane_painter.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_apply_view_range_ppb.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_set_pixels_per_beat.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_sync_ruler.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_overlay.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_marker_handle.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_playhead_widgets.dart';
part 'midi_take_comp_view_private_midi_take_comp_view_state_lane.dart';

class MidiTakeCompView extends StatefulWidget {
  const MidiTakeCompView({
    super.key,
    required this.compNotes,
    required this.takes,
    required this.regions,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.playheadBeat,
    required this.selectedMarker,
    required this.onPlayheadSeek,
    required this.onMarkerSelected,
    required this.onMarkerMove,
    required this.onMarkerMoveEnd,
    required this.onTakeAtBeat,
    this.readOnly = false,
    this.viewRangeBars = EditorViewRange.defaultBars,
    this.compTool = MidiCompTool.comp,
  });

  final List<MidiNoteSnapshot> compNotes;
  final List<MidiClipTakeSnapshot> takes;
  final List<MidiClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final double playheadBeat;
  final int? selectedMarker;
  final ValueChanged<double> onPlayheadSeek;
  final ValueChanged<int> onMarkerSelected;
  final void Function(int index, double beat) onMarkerMove;
  final void Function(int index, double beat) onMarkerMoveEnd;
  final void Function(String takeId, double beat) onTakeAtBeat;

  /// When true the comp is flattened: marker drag/select and take reassignment
  /// are frozen (the derived notes are no longer authoritative).
  final bool readOnly;

  /// Horizontal zoom preset — kept in sync with the Notes editor View sheet.
  final int viewRangeBars;

  /// Bottom-dock interaction mode (Move / Comp / Markers).
  final MidiCompTool compTool;

  @override
  State<MidiTakeCompView> createState() => _MidiTakeCompViewState();
}
