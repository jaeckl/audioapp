library;

part 'piano_roll_metrics_piano_roll_tool.dart';
part 'piano_roll_metrics_piano_roll_draw_pattern.dart';
part 'piano_roll_metrics_piano_roll_snap.dart';
part 'piano_roll_metrics_piano_roll_grid_settings.dart';

part 'piano_roll_metrics_piano_roll_snap_label.dart';
/// Layout tokens and helpers for the piano roll editor.
class PianoRollMetrics {
  const PianoRollMetrics._();

  static const double keyColumnWidth = 36;

  static const double rulerHeight = 24;

  static const double toolDockHeight = 48;

  /// Default zoom — user can pinch or scroll to change.

  static const double rowHeight = 28;

  static const double pixelsPerBeat = 44;

  static const double minRowHeight = 14;

  static const double maxRowHeight = 52;

  static const double minPixelsPerBeat = 22;

  /// High enough for comfortable 1/16-note editing at max pinch zoom.
  static const double maxPixelsPerBeat = 384;

  static const double noteResizeHandle = 20;

  static const double clipBoundaryWidth = 2;
  static const double clipEndHitWidth = 28;
  static const double clipEndLineWidth = 2;

  static const double noteVerticalInset = 4;

  static const int centerPitch = 60;

  static const int semitonesPerOctave = 12;

  /// Full scrollable pitch range in the editor grid.

  static const int gridMinPitch = 0; // C-1 (MIDI/DAW convention)

  static const int gridMaxPitch = 127; // G9

  static const double barsPadding = 8;

  static const double minVirtualBars = 16;

  static const int beatsPerBar = 4;

  static const double defaultNoteBeats = 1.0; // 1/4 note

  static const int defaultVisibleSemitones = 12; // one octave

  /// Row height so [semitones] fill the piano-roll body viewport.
  static double rowHeightForVisibleSemitones(
    double viewportHeight, {
    int semitones = defaultVisibleSemitones,
  }) {
    if (viewportHeight <= 0 || semitones <= 0) return rowHeight;
    return (viewportHeight / semitones).clamp(minRowHeight, maxRowHeight);
  }

  static int pitchCount(int minP, int maxP) => maxP - minP + 1;

  static double gridWidth(double lengthBeats, double pixelsPerBeat) =>
      lengthBeats * pixelsPerBeat;

  static double gridHeight(int minP, int maxP, double rowHeight) =>
      pitchCount(minP, maxP) * rowHeight;

  static int initialOctaveOffset(Iterable<int> pitches) {
    if (pitches.isEmpty) return 0;

    final sorted = pitches.toList()..sort();

    final median = sorted[sorted.length ~/ 2];

    return ((median - centerPitch) / semitonesPerOctave).round();
  }

  static int octaveOffsetFromPitch(int pitch) =>
      ((pitch - centerPitch) / semitonesPerOctave).round();

  static double initialVerticalScrollOffset({
    required Iterable<int> pitches,
    required int minPitch,
    required int maxPitch,
    required double rowHeight,
    required double viewportHeight,
  }) {
    final focus = pitches.isEmpty
        ? centerPitch
        : (() {
            final sorted = pitches.toList()..sort();

            return sorted[sorted.length ~/ 2];
          })();

    final row = (maxPitch - focus) * rowHeight;

    final target = row - viewportHeight / 2 + rowHeight / 2;

    final maxScroll =
        PianoRollMetrics.gridHeight(minPitch, maxPitch, rowHeight) -
            viewportHeight;

    return target.clamp(0.0, maxScroll > 0 ? maxScroll : 0.0);
  }

  static double virtualLengthBeats(double clipLengthBeats) {
    final padded = clipLengthBeats + barsPadding * beatsPerBar;

    final minimum = minVirtualBars * beatsPerBar;

    return padded > minimum ? padded : minimum;
  }

  static String pitchLetter(int pitch) {
    const names = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];

    return names[pitch % 12];
  }

  static String noteLabel(int pitch) {
    return '${pitchLetter(pitch)}${(pitch ~/ 12) - 1}';
  }

  static String octaveLabel(int pitch) {
    final octave = (pitch ~/ 12) - 1;

    return 'C$octave';
  }
}
