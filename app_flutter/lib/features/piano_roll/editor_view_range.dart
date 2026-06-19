import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';

/// Horizontal zoom presets for MIDI and automation clip editors.
abstract final class EditorViewRange {
  static const bars = [1, 2, 4, 8, 16];
  static const defaultBars = 4;

  static double visibleBeatsForBars(int bars) =>
      bars * PianoRollMetrics.beatsPerBar.toDouble();

  static double pixelsPerBeatForWidth(double viewportWidth, int visibleBars) {
    if (viewportWidth <= 0 || visibleBars <= 0) {
      return PianoRollMetrics.pixelsPerBeat;
    }
    final visibleBeats = visibleBeatsForBars(visibleBars);
    return (viewportWidth / visibleBeats).clamp(
      PianoRollMetrics.minPixelsPerBeat,
      PianoRollMetrics.maxPixelsPerBeat,
    );
  }
}

class EditorViewRangeDropdown extends StatelessWidget {
  const EditorViewRangeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        isDense: true,
        icon: const Icon(Icons.unfold_more, size: 18, color: Colors.white54),
        dropdownColor: const Color(0xFF2A2A36),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        items: [
          for (final bars in EditorViewRange.bars)
            DropdownMenuItem(
              value: bars,
              child: Text('$bars bar${bars == 1 ? '' : 's'}'),
            ),
        ],
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}
