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
    this.top,
    this.groupHighlight = false,
    this.showLeftResizeHandle = false,
    this.showRightResizeHandle = false,
  });

  final MidiNoteSnapshot note;
  final bool selected;
  final bool groupHighlight;
  final bool showLeftResizeHandle;
  final bool showRightResizeHandle;
  final double pixelsPerBeat;
  final double rowHeight;
  final int maxPitch;
  final double? top;

  @override
  Widget build(BuildContext context) {
    final inset = PianoRollMetrics.noteVerticalInset;
    final width = note.durationBeats * pixelsPerBeat;
    final handleW = math.min(PianoRollMetrics.noteResizeHandle, width / 2);
    final hot = selected;
    final inGroup = groupHighlight;
    final showLeft = showLeftResizeHandle && handleW >= 4;
    final showRight = showRightResizeHandle && handleW >= 4;

    return Positioned(
      left: note.startBeat * pixelsPerBeat,
      top: (top ?? (maxPitch - note.pitch) * rowHeight) + inset,
      width: width,
      height: rowHeight - inset * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: hot
                    ? PianoRollTheme.noteSelected
                    : inGroup
                        ? PianoRollTheme.noteSelected.withValues(alpha: 0.55)
                        : PianoRollTheme.noteFill,
                borderRadius: BorderRadius.circular(6),
                border: hot || inGroup
                    ? Border.all(
                        color: PianoRollTheme.noteBorderSelected,
                        width: hot ? 1.5 : 1,
                      )
                    : Border.all(color: PianoRollTheme.noteBorder, width: 0.5),
              ),
            ),
          ),
          if (showLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: handleW,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(6),
                  ),
                ),
              ),
            ),
          if (showRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: handleW,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
