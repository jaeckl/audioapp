import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/percussion_panel_layout.dart';
import 'package:audioapp/features/device_strip/snare_generator_device_panel.dart';

void main() {
  const snare = SnareGeneratorDeviceSnapshot(
    id: 's1',
    gain: 1.0,
    pan: 0.5,
    bypassed: false,
    meterGainReductionDb: 0.0,
    meterInputLevel: 0.0,
    snareModel: 0.0,
    snareBody: 0.5,
    snareRing: 0.5,
    snareTune: 0.5,
    snareSnares: 0.5,
    snareSnap: 0.5,
    snareDecay: 0.5,
    snareVelocity: 1.0,
  );

  testWidgets('snare uses compact unnamed percussion cards', (tester) async {
    expect(DeviceStripMetrics.designWidthFor('snare_generator'),
        DeviceStripMetrics.kickDesignWidth);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
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
    expect(find.byType(PercussionControlCard), findsNWidgets(2));
    expect(find.text('Acoustic'), findsNothing);
    expect(find.text('Tight'), findsNothing);
    expect(find.text('909'), findsNothing);
  });
}
