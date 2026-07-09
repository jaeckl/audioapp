import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/mood_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stutter device snapshot parses phase one parameters', () {
    final snapshot = DeviceSnapshot.fromMap({
      'id': 'stutter-1',
      'type': 'stutter_fx',
      'bypass': 0.0,
      'parameters': {
        'trigger': 1.0,
        'captureMs': 750.0,
        'rateSync': 1.0,
        'rateBeats': 0.125,
        'rateMs': 62.5,
        'windowMs': 48.0,
        'position': 0.35,
        'gate': 0.7,
        'fadeMs': 5.0,
        'direction': 2.0,
        'mix': 0.8,
        'duck': 0.25,
        'outputGain': 1.2,
      },
      'outputPanel': {
        'gain': 0.9,
        'pan': 0.6,
        'outputMix': 0.95,
        'outputWidth': 0.85,
      },
      'meters': {
        'gainReductionDb': -1.0,
        'inputLevel': 0.5,
      },
    }) as StutterDeviceSnapshot;

    expect(snapshot.id, 'stutter-1');
    expect(snapshot.trigger, 1.0);
    expect(snapshot.captureMs, 750.0);
    expect(snapshot.rateSync, 1.0);
    expect(snapshot.rateBeats, 0.125);
    expect(snapshot.rateMs, 62.5);
    expect(snapshot.windowMs, 48.0);
    expect(snapshot.position, 0.35);
    expect(snapshot.gate, 0.7);
    expect(snapshot.fadeMs, 5.0);
    expect(snapshot.direction, 2.0);
    expect(snapshot.mix, 0.8);
    expect(snapshot.duck, 0.25);
    expect(snapshot.outputGain, 1.2);
    expect(snapshot.outputMix, 0.95);
    expect(snapshot.outputWidth, 0.85);
  });

  test('stutter device snapshot updates modulatable parameters', () {
    final base = DeviceSnapshot.fromMap({
      'id': 'stutter-1',
      'type': 'stutter_fx',
    }) as StutterDeviceSnapshot;

    expect(base.withParameter('trigger', 1.0).trigger, 1.0);
    expect(base.withParameter('rateSync', 0.0).rateSync, 0.0);
    expect(base.withParameter('rateBeats', 0.125).rateBeats, 0.125);
    expect(base.withParameter('rateMs', 250.0).rateMs, 250.0);
    expect(base.withParameter('windowMs', 120.0).windowMs, 120.0);
    expect(base.withParameter('position', 0.8).position, 0.8);
    expect(base.withParameter('gate', 0.4).gate, 0.4);
    expect(base.withParameter('mix', 0.6).mix, 0.6);
    expect(base.withParameter('duck', 0.2).duck, 0.2);
  });

  test('stutter device uses mood fx strip sizing', () {
    expect(
      DeviceStripMetrics.designWidthFor('stutter_fx'),
      216,
    );
  });

  testWidgets('stutter panel exposes hold as a toggle without overflow',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'stutter-1',
      'type': 'stutter_fx',
    }) as StutterDeviceSnapshot;
    final changes = <String, double>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: StutterFxPanel.designWidth,
            height: DeviceStripMetrics.height,
            child: StutterFxPanel(
              device: device,
              onParameterChanged: (id, value) => changes[id] = value,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('HOLD'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('1/4'), findsWidgets);

    await tester.tap(find.text('HOLD'));
    await tester.pump();

    expect(changes['trigger'], 1.0);
    expect(tester.takeException(), isNull);
  });
}
