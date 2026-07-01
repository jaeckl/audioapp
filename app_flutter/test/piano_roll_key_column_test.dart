import 'package:audioapp/features/piano_roll/piano_roll_key_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping piano rail previews its pitch', (tester) async {
    int? tappedPitch;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PianoRollKeyColumn(
            minPitch: 60,
            maxPitch: 60,
            rowHeight: 40,
            onPitchTap: (pitch) => tappedPitch = pitch,
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('C4')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tappedPitch, 60);
    await gesture.up();
  });
}
