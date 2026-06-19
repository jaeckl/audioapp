import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/snare_generator_device_panel.dart';

void main() {
  const snare = DeviceSnapshot(
    id: 's1',
    type: 'snare_generator',
    frequencyHz: 440,
    gain: 1,
    pan: 0.5,
    sampleId: '',
    attack: 0,
    decay: 0,
    sustain: 0,
    release: 0,
    filterCutoff: 1,
    filterQ: 0.5,
    filterMode: 0,
    trimStartSec: 0,
    trimEndSec: 0,
  );

  testWidgets('snare bench uses kick layout width', (tester) async {
    expect(DeviceStripMetrics.designWidthFor('snare_generator'),
        DeviceStripMetrics.kickDesignWidth);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 280,
            child: SnareGeneratorDevicePanel(
              device: snare,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Ring'), findsOneWidget);
    expect(find.text('Snares'), findsOneWidget);
    expect(find.text('Acoustic'), findsOneWidget);
  });
}
