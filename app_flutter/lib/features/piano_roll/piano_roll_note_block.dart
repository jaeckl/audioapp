import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

class PianoRollNoteBlock extends StatelessWidget {
  const PianoRollNoteBlock({
    super.key,
    required this.note,
    required this.selected,
    required this.pixelsPerBeat,
    required this.rowHeight,
    required this.maxPitch,
  });

  final MidiNoteSnapshot note;
  final bool selected;
  final double pixelsPerBeat;
  final double rowHeight;
  final int maxPitch;

  @override
  Widget build(BuildContext context) {
    final inset = PianoRollMetrics.noteVerticalInset;
    final width = note.durationBeats * pixelsPerBeat;
    final handleW =
        math.min(PianoRollMetrics.noteResizeHandle, width / 2);

    return Positioned(
      left: note.startBeat * pixelsPerBeat,
      top: (maxPitch - note.pitch) * rowHeight + inset,
      width: width,
      height: rowHeight - inset * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? PianoRollTheme.noteSelected : PianoRollTheme.noteFill,
                borderRadius: BorderRadius.circular(6),
                border: selected
                    ? Border.all(color: PianoRollTheme.noteBorderSelected, width: 1.5)
                    : Border.all(color: PianoRollTheme.noteBorder, width: 0.5),
              ),
            ),
          ),
          if (selected && handleW >= 4)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: handleW,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                ),
                child: const Center(
                  child: Icon(Icons.drag_handle, size: 14, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
