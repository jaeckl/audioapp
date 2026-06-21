import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/crash_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/cymbal_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';

void main() {
  const cymbal = CymbalGeneratorDeviceSnapshot(
    id: 'c1',
    gain: 1.0,
    pan: 0.5,
    bypassed: false,
    meterGainReductionDb: 0.0,
    meterInputLevel: 0.0,
    cymbalModel: 0.0,
    cymbalColor: 0.5,
    cymbalDecay: 0.5,
    cymbalVelocity: 1.0,
    cymbalWidth: 0.35,
  );

  const crash = CrashGeneratorDeviceSnapshot(
    id: 'cr1',
    gain: 1.0,
    pan: 0.5,
    bypassed: false,
    meterGainReductionDb: 0.0,
    meterInputLevel: 0.0,
    crashModel: 0.0,
    crashColor: 0.5,
    crashSpread: 0.5,
    crashDecay: 0.55,
    crashVelocity: 1.0,
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
