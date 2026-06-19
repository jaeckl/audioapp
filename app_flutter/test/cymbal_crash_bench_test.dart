import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/crash_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/cymbal_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';

void main() {
  const cymbal = DeviceSnapshot(
    id: 'c1',
    type: 'cymbal_generator',
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

  const crash = DeviceSnapshot(
    id: 'cr1',
    type: 'crash_generator',
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

  testWidgets('cymbal bench uses kick layout width', (tester) async {
    expect(DeviceStripMetrics.designWidthFor('cymbal_generator'),
        DeviceStripMetrics.kickDesignWidth);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 280,
            child: CymbalGeneratorDevicePanel(
              device: cymbal,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('crash bench shows color and spread knobs', (tester) async {
    expect(DeviceStripMetrics.designWidthFor('crash_generator'),
        DeviceStripMetrics.kickDesignWidth);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 280,
            child: CrashGeneratorDevicePanel(
              device: crash,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Spread'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
  });
}
