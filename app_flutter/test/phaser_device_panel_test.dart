import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/time_fx_panels.dart';
import 'package:audioapp/features/device_strip/value_drag_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PhaserDeviceSnapshot _phaser() => const PhaserDeviceSnapshot(
      id: 'phaser-1',
      gain: 1,
      pan: .5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      outputMix: .5,
      outputWidth: 1,
      phaserDepth: .72,
      phaserRateHz: .8,
      phaserFeedback: .38,
      phaserCentreFrequencyHz: 1200,
    );

Widget _host(
  PhaserDeviceSnapshot device,
  void Function(String, double) changed,
) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: PhaserFxPanel.designWidth,
          height: 280,
          child: PhaserFxPanel(
            device: device,
            onParameterChanged: changed,
          ),
        ),
      ),
    );

void main() {
  testWidgets('phaser face exposes rails, plate knobs, waveform group',
      (tester) async {
    await tester.pumpWidget(_host(_phaser(), (_, __) {}));

    expect(find.text('8th'), findsWidgets);
    for (final label in [
      'Depth',
      'Stereo Phase',
      'Wave Shape',
      'LFO Phase',
      'Centre',
      'Feedback',
      'Stages',
      'SIN',
      'TRI',
      'RMP',
      'RND',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('phaser-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('phaser-waveform-selector')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('phaser-view-motion')), findsOneWidget);
    expect(find.byKey(const ValueKey('phaser-view-response')), findsOneWidget);
    expect(
      tester.widget<ValueDragBox>(find.byType(ValueDragBox)).dragPixelsPerStep,
      32,
    );
    expect(PhaserFxPanel.designWidth, 424);
    expect(PhaserFxPanel.containerTabs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waveform cells and view toggle change state', (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(_host(
      _phaser(),
      (id, value) => changes.add((id, value)),
    ));

    await tester.tap(find.text('TRI'));
    await tester.pump();
    expect(changes, contains(('waveform', 1.0)));

    await tester.tap(find.byKey(const ValueKey('phaser-view-response')));
    await tester.pump();
    expect(
      tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('phaser-view-response')),
        matching: find.byType(Icon),
      )).color,
      PhaserFxPanel.accent,
    );

    await tester.tap(find.byKey(const ValueKey('knob-label-menu-8th')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4th').last);
    await tester.pumpAndSettle();
    expect(changes, contains(('rateMode', 3.0)));
    expect(tester.takeException(), isNull);
  });

  test('snapshot parses and updates advanced phaser parameters', () {
    final snapshot = DeviceSnapshot.fromMap({
      'id': 'phaser-map',
      'type': 'phaser',
      'parameters': {
        'depth': .6,
        'rateHz': 1.2,
        'feedback': .4,
        'centreFrequencyHz': 900,
        'rateMode': 1,
        'waveform': 2,
        'waveShape': .7,
        'phaseOffset': .25,
        'stereoPhase': .8,
        'stages': 10,
      },
    }) as PhaserDeviceSnapshot;

    expect(snapshot.phaserRateMode, 1);
    expect(snapshot.phaserWaveform, 2);
    expect(snapshot.phaserStages, 10);
    expect(snapshot.withParameter('stereoPhase', .5).phaserStereoPhase, .5);
  });
}
