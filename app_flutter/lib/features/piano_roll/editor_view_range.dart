import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';

part 'editor_view_range_editor_view_range_dropdown.dart';
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
      1.0,
      PianoRollMetrics.maxPixelsPerBeat,
    );
  }
}
