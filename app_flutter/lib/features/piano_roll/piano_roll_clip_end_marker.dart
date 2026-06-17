import 'package:flutter/material.dart';

import 'piano_roll_theme.dart';

/// Draggable handle shown on the beat ruler at the clip end.
class PianoRollClipEndPill extends StatelessWidget {
  const PianoRollClipEndPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: PianoRollTheme.clipBoundary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.drag_indicator, size: 16, color: Colors.white),
      ),
    );
  }
}

/// Vertical boundary line on the note canvas (pill lives on the ruler row).
class PianoRollClipEndLine extends StatelessWidget {
  const PianoRollClipEndLine({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: PianoRollTheme.clipEndLineWidth,
          color: PianoRollTheme.clipBoundary,
        ),
      ),
    );
  }
}
