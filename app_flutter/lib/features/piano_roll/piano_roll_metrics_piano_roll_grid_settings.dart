part of 'piano_roll_metrics.dart';

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

  /// Duration for a newly inserted or tap-drawn note (not drag-painted length).
  double get insertNoteDurationBeats {
    var duration = defaultNoteBeats;
    if (snap != PianoRollSnap.off && snapBeats > 0) {
      duration = snapBeat(duration);
      if (duration < snapBeats) {
        duration = snapBeats;
      }
    }
    return duration;
  }
}
