import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/devices/frequency_fx/frequency_shifter_definition.dart';
import 'package:audioapp/features/device_strip/frequency_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ring mod snapshot defaults', () {
    final snapshot = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'rm-1',
      'type': 'frequency_shifter',
      'parameters': <dynamic, dynamic>{},
    }) as FrequencyShifterDeviceSnapshot;

    expect(snapshot.ffxShift, 0.5);
    expect(snapshot.ffxFine, 0.5);
    expect(snapshot.ffxMix, 1.0);
    expect(snapshot.ffxTone, 1.0);
    expect(snapshot.ffxFeedback, 0.0);
  });

  test('ring mod chrome is full-bleed + empty input', () {
    final layout = FrequencyShifterDefinition().layout;
    expect(layout.designWidth, 300);
    expect(layout.inputPanelWidth, 0);
    expect(layout.outputPanelWidth, 64);
  });

  testWidgets('ring mod plate shows Shift Fine Mix Tone FB', (tester) async {
    final device = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'rm-1',
      'type': 'frequency_shifter',
      'parameters': <dynamic, dynamic>{},
    }) as FrequencyShifterDeviceSnapshot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 260,
            child: FreqShifterDevicePanel(
              device: device,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('RING'), findsOneWidget);
    expect(find.text('SHIFT'), findsOneWidget);
    expect(find.text('FINE'), findsOneWidget);
    expect(find.text('MIX'), findsOneWidget);
    expect(find.text('TONE'), findsOneWidget);
    expect(find.text('FB'), findsOneWidget);
  });
}
