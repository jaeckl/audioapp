import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/mood_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distortion snapshot parses drive sym tone', () {
    final snapshot = DeviceSnapshot.fromMap({
      'id': 'dist-1',
      'type': 'distortion',
      'bypass': 0.0,
      'parameters': {
        'drive': 0.7,
        'sym': 0.2,
        'tone': 0.4,
        'mix': 0.9,
      },
      'outputPanel': {
        'gain': 1.0,
        'pan': 0.5,
        'outputMix': 0.8,
        'outputWidth': 1.0,
      },
      'meters': {
        'gainReductionDb': 0.0,
        'inputLevel': 0.0,
      },
    }) as DistortionDeviceSnapshot;

    expect(snapshot.distDrive, 0.7);
    expect(snapshot.distSym, 0.2);
    expect(snapshot.distTone, 0.4);
    expect(snapshot.outputMix, 0.8);
  });

  test('distortion snapshot defaults missing sym to center', () {
    final snapshot = DeviceSnapshot.fromMap({
      'id': 'dist-legacy',
      'type': 'distortion',
      'parameters': {
        'drive': 0.5,
        'tone': 0.5,
      },
      'outputPanel': {},
      'meters': {},
    }) as DistortionDeviceSnapshot;

    expect(snapshot.distSym, 0.5);
  });

  test('distortion withParameter updates distSym aliases', () {
    final base = DeviceSnapshot.fromMap({
      'id': 'dist-1',
      'type': 'distortion',
    }) as DistortionDeviceSnapshot;

    expect(base.withParameter('distSym', 0.1).distSym, 0.1);
    expect(base.withParameter('sym', 0.9).distSym, 0.9);
    expect(base.withParameter('distDrive', 0.3).distDrive, 0.3);
  });

  testWidgets('distortion panel shows Drive Sym Tone without overflow',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dist-1',
      'type': 'distortion',
    }) as DistortionDeviceSnapshot;
    final changes = <String, double>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: DistortionFxPanel.designWidth,
            height: DeviceStripMetrics.height,
            child: DistortionFxPanel(
              device: device,
              onParameterChanged: (id, value) => changes[id] = value,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('DRIVE'), findsOneWidget);
    expect(find.text('SYM'), findsOneWidget);
    expect(find.text('TONE'), findsOneWidget);
  });
}
