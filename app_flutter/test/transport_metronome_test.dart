import 'package:audioapp/features/transport/transport_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('metronome menu changes click and count-in settings',
      (tester) async {
    bool? enabled;
    double? level;
    int? bars;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TransportBar(
                bpm: 120,
                playheadBeats: 0,
                playing: false,
                loopEnabled: false,
                loopRegionStartBeat: 0,
                loopRegionEndBeat: 4,
                recordArmed: false,
                followPlayheadEnabled: true,
                followPlayheadSuspended: false,
                metronomeEnabled: false,
                metronomeLevel: 0.65,
                countInBars: 1,
                onMetronomeChanged: (e, l, b) {
                  enabled = e;
                  level = l;
                  bars = b;
                }))));

    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Metronome'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(enabled, isTrue);
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(bars, 2);
    expect(level, 0.65);
  });

  testWidgets('recording mode label appears while recording', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: TransportBar(
                bpm: 120,
                playheadBeats: 2,
                playing: true,
                loopEnabled: false,
                loopRegionStartBeat: 0,
                loopRegionEndBeat: 4,
                recordArmed: true,
                recordingActive: true,
                recordingStartBeat: 0,
                recordingModeLabel: 'REC MIDI',
                followPlayheadEnabled: true,
                followPlayheadSuspended: false))));

    expect(find.text('REC MIDI'), findsOneWidget);
    expect(find.textContaining('+ AUTO'), findsNothing);
  });

  testWidgets('armed transport keeps compact position readout', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: TransportBar(
                bpm: 120,
                playheadBeats: 0,
                playing: false,
                loopEnabled: false,
                loopRegionStartBeat: 0,
                loopRegionEndBeat: 4,
                recordArmed: true,
                followPlayheadEnabled: true,
                followPlayheadSuspended: false))));

    expect(find.textContaining('+ AUTO'), findsNothing);
    expect(find.textContaining('REC AUDIO'), findsNothing);
  });
}
