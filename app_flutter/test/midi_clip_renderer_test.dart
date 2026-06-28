import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/arrangement/arrangement_clip_theme.dart';
import 'package:audioapp/features/arrangement/clip_renderer.dart';
import 'package:audioapp/features/arrangement/midi_clip_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MidiClipRenderer paints condensed notes on darker content fill', (tester) async {
    const clip = MidiClipSnapshot(
      id: 'clip-1',
      startBeat: 0,
      lengthBeats: 4,
      notes: [
        MidiNoteSnapshot(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
        MidiNoteSnapshot(pitch: 64, startBeat: 1, durationBeats: 0.5, velocity: 90),
        MidiNoteSnapshot(pitch: 67, startBeat: 2, durationBeats: 1, velocity: 80),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 52,
            child: ArrangementClipChrome(
              renderer: MidiClipRenderer(clip),
              highlighted: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('MIDI'), findsNothing);

    final renderer = const MidiClipRenderer(clip);
    expect(
      renderer.clipContentBackgroundColor,
      ArrangementClipTheme.contentBackground(ArrangementClipTheme.midiClipBackground),
    );
  });

  testWidgets('empty MIDI clip shows placeholder label', (tester) async {
    const clip = MidiClipSnapshot(
      id: 'clip-empty',
      startBeat: 0,
      lengthBeats: 4,
      notes: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 52,
            child: ArrangementClipChrome(
              renderer: MidiClipRenderer(clip),
              highlighted: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('MIDI'), findsOneWidget);
  });
}
