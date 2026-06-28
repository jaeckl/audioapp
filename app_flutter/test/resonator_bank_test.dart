import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/features/device_strip/device_picker_sheet.dart';
import 'package:audioapp/features/device_strip/resonator_bank_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resonator snapshot parses defaults and updates parameters', () {
    final snapshot = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'res-1',
      'type': 'resonator_bank',
      'parameters': <dynamic, dynamic>{'resDecay': 0.8, 'resColor': 0.25},
    }) as ResonatorBankDeviceSnapshot;

    expect(snapshot.resRoot, 0.5);
    expect(snapshot.resDecay, 0.8);
    expect(snapshot.resColor, 0.25);
    expect(snapshot.withParameter('resWidth', 2).resWidth, 1);
    expect(snapshot.withParameter('resMix', -1).resMix, 0);
  });

  testWidgets('device picker lists RESONATE', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDevicePickerSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('RESONATE'), findsOneWidget);
  });

  testWidgets('compact resonator panel renders all seven controls', (
    tester,
  ) async {
    const device = ResonatorBankDeviceSnapshot(
      id: 'res-1',
      gain: 1,
      pan: 0.5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      resRoot: 0.5,
      resSpread: 0.5,
      resDecay: 0.55,
      resDamping: 0.35,
      resColor: 0.5,
      resWidth: 0.5,
      resMix: 0.5,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: ResonatorBankPanel.designWidth,
            height: 280,
            child: ResonatorBankPanel(
              device: device,
              onParameterChanged: _ignoreParameter,
            ),
          ),
        ),
      ),
    );

    for (final label in [
      'Root',
      'Spread',
      'Decay',
      'Damping',
      'Color',
      'Width',
      'Mix',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

void _ignoreParameter(String _, double __) {}
