part of 'piano_roll_metrics.dart';

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
