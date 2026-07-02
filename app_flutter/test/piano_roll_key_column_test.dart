import 'package:audioapp/features/piano_roll/piano_roll_key_column.dart';
import 'package:audioapp/features/piano_roll/midi_lane_layout.dart';
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

  testWidgets('named drum lanes replace chromatic piano keys', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PianoRollKeyColumn(
            minPitch: 0,
            maxPitch: 127,
            rowHeight: 24,
            lanes: [
              MidiLaneDefinition(pitch: 42, name: 'Closed Hat'),
              MidiLaneDefinition(pitch: 36, name: 'Kick'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Closed Hat'), findsOneWidget);
    expect(find.text('Kick'), findsOneWidget);
    expect(find.text('C4'), findsNothing);
  });
}
