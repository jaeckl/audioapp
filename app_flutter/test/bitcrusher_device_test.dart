import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/features/device_strip/mood_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advanced bitcrusher parameters parse with backward-compatible defaults',
      () {
    final device = DeviceSnapshot.fromMap({
      'id': 'bc-1',
      'type': 'bitcrusher',
      'parameters': {'rate': .7, 'bits': 6.0},
    }) as BitcrusherDeviceSnapshot;

    expect(device.bcRate, .7);
    expect(device.bcBits, 6);
    expect(device.bcMode, 0);
    expect(device.bcDitherAmount, 0);
    expect(device.bcFilter, 1);
  });

  testWidgets('refined bitcrusher panel exposes advanced control groups',
      (tester) async {
    final device = BitcrusherDeviceSnapshot(
      id: 'bc-1',
      gain: 1,
      pan: .5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      bcRate: .5,
      bcBits: 8,
      bcMode: 0,
      bcShape: 0,
      bcJitter: 0,
      bcDrive: 0,
      bcDitherMode: 0,
      bcDitherAmount: 0,
      bcClipMode: 0,
      bcClipAmount: 0,
      bcFilter: 1,
    );
    final changes = <(String, double)>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 424,
          height: 320,
          child: Column(children: [
            SizedBox(
              height: 40,
              child: BitcrusherHeaderActions(
                device: device,
                onParameterChanged: (id, value) => changes.add((id, value)),
              ),
            ),
            Expanded(
              child: BitcrusherFxPanel(
                device: device,
                onParameterChanged: (id, value) => changes.add((id, value)),
                onModulationAssign: null,
              ),
            ),
          ]),
        ),
      ),
    ));

    expect(find.byKey(const ValueKey('bitcrusher-mode-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bitcrusher-shape-0')), findsOneWidget);
    expect(find.text('No Dither'), findsOneWidget);
    expect(find.text('No Clip'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bitcrusher-mode-1')));
    expect(changes.last, ('bcMode', 1.0));
  });
}
