import 'dart:math' as math;

import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/devices/frequency_fx/four_band_eq_definition.dart';
import 'package:audioapp/features/device_strip/eq_preview.dart';
import 'package:audioapp/features/device_strip/frequency_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four-band EQ snapshot defaults Q ~Butterworth', () {
    final snapshot = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'eq-1',
      'type': 'four_band_eq',
      'parameters': <dynamic, dynamic>{},
    }) as FourBandEqDeviceSnapshot;

    expect(snapshot.ffxBand1Q, 0.03);
    expect(snapshot.ffxBand2Q, 0.03);
    expect(snapshot.ffxBand3Q, 0.03);
    expect(snapshot.ffxBand4Q, 0.03);
    expect(snapshot.ffxBand1Gain, 0.5);
  });

  test('four-band EQ chrome is full-bleed Filter archetype', () {
    final layout = FourBandEqDefinition().layout;
    expect(layout.designWidth, 280);
    expect(layout.inputPanelWidth, 0);
    expect(layout.outputPanelWidth, 64);
  });

  testWidgets('four-band EQ plate shows band select + knobs', (tester) async {
    final device = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'eq-1',
      'type': 'four_band_eq',
      'parameters': <dynamic, dynamic>{},
    }) as FourBandEqDeviceSnapshot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 220,
            child: FourBandEqDevicePanel(
              device: device,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('LS'), findsOneWidget);
    expect(find.text('LM'), findsOneWidget);
    expect(find.text('HM'), findsOneWidget);
    expect(find.text('HS'), findsOneWidget);
    expect(find.text('FREQ'), findsOneWidget);
    expect(find.text('GAIN'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    // Scale labels live in CustomPaint — smoke via geometry constants.
    expect(EqPreviewGeometry.freqLabels.map((e) => e.$2).toList(),
        ['20', '100', '1k', '10k', '20k']);
    expect(EqPreviewGeometry.dbLabels.map((e) => e.$2).toList(),
        ['+24', '+12', '0', '−12', '−24']);
  });

  testWidgets('EQ handle drag updates freq + gain', (tester) async {
    var device = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'eq-1',
      'type': 'four_band_eq',
      'parameters': <dynamic, dynamic>{
        'ffxBand1Freq': 0.15,
        'ffxBand1Gain': 0.5,
        'ffxBand1Q': 0.03,
        'ffxBand2Freq': 0.35,
        'ffxBand2Gain': 0.5,
        'ffxBand2Q': 0.03,
        'ffxBand3Freq': 0.6,
        'ffxBand3Gain': 0.5,
        'ffxBand3Q': 0.03,
        'ffxBand4Freq': 0.85,
        'ffxBand4Gain': 0.5,
        'ffxBand4Q': 0.03,
      },
    }) as FourBandEqDeviceSnapshot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 280,
                height: 260,
                child: FourBandEqDevicePanel(
                  device: device,
                  onParameterChanged: (id, value) {
                    setState(() {
                      device = device.withParameter(id, value)
                          as FourBandEqDeviceSnapshot;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    final preview = find.byType(FourBandEqPreview);
    expect(preview, findsOneWidget);
    final box = tester.renderObject<RenderBox>(preview);
    final origin = box.localToGlobal(Offset.zero);

    final hz = 20.0 * math.pow(1000.0, device.ffxBand1Freq);
    final db = -24.0 + device.ffxBand1Gain * 48.0;
    final handle = EqPreviewGeometry.handleOffset(
      EqBand(cutoffHz: hz, gainDb: db, q: 0.71, isShelf: true),
      box.size,
    );

    await tester.timedDragFrom(
      origin + handle,
      const Offset(40, -30),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();

    expect(device.ffxBand1Freq, isNot(closeTo(0.15, 0.001)));
    expect(device.ffxBand1Gain, isNot(closeTo(0.5, 0.001)));
  });
}
