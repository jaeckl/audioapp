import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/piano_roll/piano_roll_metrics.dart';
import 'package:audioapp/features/piano_roll/piano_roll_note_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short sixteenth note renders without layout error', (tester) async {
    const note = MidiNoteSnapshot(
      pitch: 60,
      startBeat: 0,
      durationBeats: PianoRollMetrics.defaultNoteBeats,
      velocity: 100,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 100,
            child: Stack(
              children: [
                PianoRollNoteBlock(
                  note: note,
                  selected: true,
                  pixelsPerBeat: PianoRollMetrics.pixelsPerBeat,
                  rowHeight: PianoRollMetrics.rowHeight,
                  maxPitch: PianoRollMetrics.gridMaxPitch,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PianoRollNoteBlock), findsOneWidget);
  });
}
