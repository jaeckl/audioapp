import 'package:audioapp/features/piano_roll/piano_roll_grid_painter.dart';
import 'package:audioapp/features/piano_roll/piano_roll_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visible grid step follows snap settings at readable zoom', () {
    expect(
      PianoRollGridPainter.visibleGridStepBeats(
        gridSettings: const PianoRollGridSettings(snap: PianoRollSnap.eighth),
        pixelsPerBeat: 64,
      ),
      0.5,
    );

    expect(
      PianoRollGridPainter.visibleGridStepBeats(
        gridSettings: const PianoRollGridSettings(
          snap: PianoRollSnap.sixteenth,
        ),
        pixelsPerBeat: 64,
      ),
      0.25,
    );
  });

  test('visible grid step supports triplet snap settings', () {
    expect(
      PianoRollGridPainter.visibleGridStepBeats(
        gridSettings: const PianoRollGridSettings(
          snap: PianoRollSnap.eighth,
          triplet: true,
        ),
        pixelsPerBeat: 64,
      ),
      closeTo(1 / 3, 0.000001),
    );
  });

  test('visible grid step coarsens dense subdivisions when zoomed out', () {
    expect(
      PianoRollGridPainter.visibleGridStepBeats(
        gridSettings: const PianoRollGridSettings(
          snap: PianoRollSnap.thirtySecond,
        ),
        pixelsPerBeat: 22,
      ),
      0.5,
    );
  });

  test('visible grid step falls back to beat grid when snap is off', () {
    expect(
      PianoRollGridPainter.visibleGridStepBeats(
        gridSettings: const PianoRollGridSettings(snap: PianoRollSnap.off),
        pixelsPerBeat: 64,
      ),
      1.0,
    );
  });
}
