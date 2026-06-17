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

  static const double maxPixelsPerBeat = 96;



  static const double noteResizeHandle = 20;

  static const double clipBoundaryWidth = 2;
  static const double clipEndHitWidth = 28;
  static const double clipEndLineWidth = 2;

  static const double noteVerticalInset = 4;



  static const int centerPitch = 60;

  static const int semitonesPerOctave = 12;



  /// Full scrollable pitch range in the editor grid.

  static const int gridMinPitch = 36; // C2

  static const int gridMaxPitch = 96; // C7



  static const double barsPadding = 8;

  static const double minVirtualBars = 16;

  static const int beatsPerBar = 4;



  static const double defaultNoteBeats = 0.25;



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

        PianoRollMetrics.gridHeight(minPitch, maxPitch, rowHeight) - viewportHeight;

    return target.clamp(0.0, maxScroll > 0 ? maxScroll : 0.0);

  }



  static double virtualLengthBeats(double clipLengthBeats) {

    final padded = clipLengthBeats + barsPadding * beatsPerBar;

    final minimum = minVirtualBars * beatsPerBar;

    return padded > minimum ? padded : minimum;

  }



  static String pitchLetter(int pitch) {

    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    return names[pitch % 12];

  }



  static String octaveLabel(int pitch) {

    final octave = (pitch ~/ 12) - 1;

    return 'C$octave';

  }

}



enum PianoRollTool { select, draw }



enum PianoRollSnap {

  off,

  whole,

  half,

  quarter,

  eighth,

  sixteenth,

  thirtySecond,

}



extension PianoRollSnapLabel on PianoRollSnap {

  String get shortLabel => switch (this) {

        PianoRollSnap.off => 'Off',

        PianoRollSnap.whole => '1/1',

        PianoRollSnap.half => '1/2',

        PianoRollSnap.quarter => '1/4',

        PianoRollSnap.eighth => '1/8',

        PianoRollSnap.sixteenth => '1/16',

        PianoRollSnap.thirtySecond => '1/32',

      };



  double beats({bool triplet = false}) {

    if (this == PianoRollSnap.off) return 0;

    final base = switch (this) {

      PianoRollSnap.whole => 4.0,

      PianoRollSnap.half => 2.0,

      PianoRollSnap.quarter => 1.0,

      PianoRollSnap.eighth => 0.5,

      PianoRollSnap.sixteenth => 0.25,

      PianoRollSnap.thirtySecond => 0.125,

      PianoRollSnap.off => 0.25,

    };

    return triplet ? base * (2 / 3) : base;

  }

}



enum PianoRollSaveState { saved, saving, error }



class PianoRollGridSettings {

  const PianoRollGridSettings({

    this.snap = PianoRollSnap.sixteenth,

    this.triplet = false,

    this.defaultNoteBeats = PianoRollMetrics.defaultNoteBeats,

  });



  final PianoRollSnap snap;

  final bool triplet;

  final double defaultNoteBeats;



  double get snapBeats => snap.beats(triplet: triplet);



  PianoRollGridSettings copyWith({

    PianoRollSnap? snap,

    bool? triplet,

    double? defaultNoteBeats,

  }) {

    return PianoRollGridSettings(

      snap: snap ?? this.snap,

      triplet: triplet ?? this.triplet,

      defaultNoteBeats: defaultNoteBeats ?? this.defaultNoteBeats,

    );

  }



  double snapBeat(double beat) {

    if (snap == PianoRollSnap.off || snapBeats <= 0) return beat;

    return (beat / snapBeats).round() * snapBeats;

  }

}


