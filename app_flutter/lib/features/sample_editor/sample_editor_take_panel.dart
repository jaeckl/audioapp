import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/arrangement_loop_region_marker.dart';

part 'sample_editor_take_panel_sample_editor_take_tools_panel.dart';
part 'sample_editor_take_panel_private_beat_badge.dart';
part 'sample_editor_take_panel_private_take_split_button.dart';
part 'sample_editor_take_panel_private_selected_marker_tile.dart';
part 'sample_editor_take_panel_private_small_take_button.dart';
part 'sample_editor_take_panel_private_boundary_mode_tile.dart';
part 'sample_editor_take_panel_private_take_wave_lane.dart';
part 'sample_editor_take_panel_private_take_wave_painter.dart';

const double sampleEditorTakeLaneHeight = 58;

class SampleEditorTakeTrackLanes extends StatelessWidget {
  const SampleEditorTakeTrackLanes({
    super.key,
    required this.takes,
    required this.regions,
    required this.clipLengthBeats,
    required this.samples,
    required this.onTakeAtBeat,
  });

  final List<SampleClipTakeSnapshot> takes;
  final List<SampleClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;
  final List<SampleLibraryEntrySnapshot> samples;
  final void Function(double beat, String takeId) onTakeAtBeat;

  @override
  Widget build(BuildContext context) {
    final sampleById = {for (final sample in samples) sample.id: sample};
    return Column(
      children: [
        for (final take in takes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _TakeWaveLane(
              take: take,
              peaks: sampleById[take.sampleId]?.waveformPeaks ?? const [],
              regions: regions,
              clipLengthBeats: clipLengthBeats,
              onBeatTap: (beat) => onTakeAtBeat(beat, take.id),
            ),
          ),
      ],
    );
  }
}
