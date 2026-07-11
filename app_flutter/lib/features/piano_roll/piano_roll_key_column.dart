import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'midi_lane_layout.dart';
import 'piano_roll_note_ops.dart';
import 'piano_roll_theme.dart';

part 'piano_roll_key_column_key_row.dart';

class PianoRollKeyColumn extends StatelessWidget {
  const PianoRollKeyColumn({
    super.key,
    required this.minPitch,
    required this.maxPitch,
    required this.rowHeight,
    this.highlightPitch,
    this.onPitchTap,
    this.lanes,
  });

  final int minPitch;
  final int maxPitch;
  final double rowHeight;

  /// GM drum lane (e.g. 38 = D2 snare) — show full note name on this row.
  final int? highlightPitch;
  final ValueChanged<int>? onPitchTap;
  final List<MidiLaneDefinition>? lanes;

  @override
  Widget build(BuildContext context) {
    final pitches = lanes?.map((lane) => lane.pitch).toList() ??
        [for (var pitch = maxPitch; pitch >= minPitch; pitch--) pitch];
    final height = pitches.length * rowHeight;
    return SizedBox(
      width: PianoRollMetrics.keyColumnWidth,
      height: height,
      child: ColoredBox(
        color: PianoRollTheme.keyColumnBackground,
        child: Column(
          children: [
            for (var row = 0; row < pitches.length; row++)
              _KeyRow(
                pitch: pitches[row],
                label: lanes
                    ?.where((lane) => lane.pitch == pitches[row])
                    .firstOrNull
                    ?.name,
                enabled: lanes
                        ?.where((lane) => lane.pitch == pitches[row])
                        .firstOrNull
                        ?.enabled ??
                    true,
                drumLane: lanes != null,
                row: row,
                rowHeight: rowHeight,
                highlight: highlightPitch == pitches[row],
                onTap:
                    onPitchTap == null ? null : () => onPitchTap!(pitches[row]),
              ),
          ],
        ),
      ),
    );
  }
}
