import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Stable per-take colors for MIDI Comp lanes, regions, and notes.
abstract final class MidiTakeColor {
  static const List<Color> palette = [
    Color(0xFF5B8DEF), // blue
    Color(0xFF6BCB77), // green
    Color(0xFFCF6A8E), // rose
    Color(0xFFFFB74D), // amber
    Color(0xFF4DB6AC), // teal
    Color(0xFF7B6CFF), // violet
    Color(0xFFFF8A65), // coral
    Color(0xFF64B5F6), // light blue
  ];

  static const Color fallback = Color(0xFF818AA4);

  static Color forIndex(int index) => palette[index % palette.length];

  static Color forTakeId(String takeId, List<MidiClipTakeSnapshot> takes) {
    final index = indexOfTakeId(takeId, takes);
    if (index < 0) return fallback;
    return forIndex(index);
  }

  static int indexOfTakeId(String takeId, List<MidiClipTakeSnapshot> takes) {
    for (var i = 0; i < takes.length; i++) {
      if (takes[i].id == takeId) return i;
    }
    return -1;
  }

  /// Region that owns [beat] on the arrangement timeline.
  static MidiClipTakeRegionSnapshot? regionAtBeat(
    List<MidiClipTakeRegionSnapshot> regions,
    double beat,
  ) {
    for (var i = 0; i < regions.length; i++) {
      final region = regions[i];
      final isLast = i == regions.length - 1;
      if (beat >= region.startBeat &&
          (beat < region.endBeat || (isLast && beat <= region.endBeat))) {
        return region;
      }
    }
    return null;
  }

  /// True when [note] onset falls in [takeId]'s winning source window.
  static bool noteWinsOnTake({
    required MidiNoteSnapshot note,
    required String takeId,
    required List<MidiClipTakeRegionSnapshot> regions,
  }) {
    for (final region in regions) {
      if (region.takeId != takeId) continue;
      final regionLength = region.endBeat - region.startBeat;
      if (regionLength <= 0) continue;
      final srcStart = region.sourceStart;
      final srcEnd = region.sourceStart + regionLength;
      if (note.startBeat >= srcStart && note.startBeat < srcEnd) {
        return true;
      }
    }
    return false;
  }

  static Color regionFill(Color accent) => accent.withValues(alpha: 0.16);

  static Color regionBorder(Color accent) => accent.withValues(alpha: 0.55);

  static Color noteFill(Color accent, {required bool winning}) =>
      accent.withValues(alpha: winning ? 0.78 : 0.22);

  static Color noteStroke({required bool winning}) =>
      Colors.black.withValues(alpha: winning ? 0.34 : 0.18);

  static Color laneAccentBorder(Color accent, {required bool highlighted}) =>
      accent.withValues(alpha: highlighted ? 0.85 : 0.35);

  static Color laneAccentFill(Color accent, {required bool highlighted}) =>
      accent.withValues(alpha: highlighted ? 0.14 : 0.06);
}
