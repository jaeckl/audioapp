import 'package:audioapp/features/piano_roll/piano_roll_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insertNoteDurationBeats uses default note length not snap grid', () {
    const settings = PianoRollGridSettings(
      snap: PianoRollSnap.sixteenth,
      defaultNoteBeats: 4.0,
    );

    expect(settings.insertNoteDurationBeats, 4.0);
  });

  test('insertNoteDurationBeats respects one bar default with eighth snap', () {
    const settings = PianoRollGridSettings(
      snap: PianoRollSnap.eighth,
      defaultNoteBeats: 0.5,
    );

    expect(settings.insertNoteDurationBeats, 0.5);
  });
}
