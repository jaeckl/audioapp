import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_chrome_panels.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrackSnapshot trackFor(List<DeviceSnapshot> devices) => TrackSnapshot(
        id: 'track-1',
        name: 'Track 1',
        devices: devices,
        midiClips: [],
        sampleClips: [],
      );

  Future<void> pumpSlot(WidgetTester tester, DeviceSnapshot device) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: DeviceStripMetrics.fullscreenHeight,
            child: DeviceStripSlot(
              track: trackFor([device]),
              device: device,
              sample: null,
              bpm: 120,
              density: DeviceStripSlotDensity.fullscreen,
              onSamplerParameterChanged: (_, __) {},
              onDeviceParameterChanged: (_, __) {},
              onOpenSamplerEditor: () {},
              onFrequencyChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const drumTypes = [
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'cymbal_generator',
    'crash_generator',
  ];

  for (final type in drumTypes) {
    testWidgets('$type uses DrumMonoOutputPanel (no pan)', (tester) async {
      final device = DeviceSnapshot.fromMap({
        'id': 'dev-$type',
        'type': type,
        'parameters': {'gain': 0.8},
      });
      await pumpSlot(tester, device);

      expect(find.text('Vel sens'), findsOneWidget);
      expect(find.text('Gain'), findsOneWidget);
      expect(find.text('Pan'), findsNothing);
    });
  }

  test('DrumMonoOutputPanel maps clap velocity param', () {
    expect(DrumMonoOutputPanel.velocityParamIdFor('clap_generator'), 'clapVelocity');
  });

  testWidgets('compressor shows GR from device meters', (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-comp',
      'type': 'compressor',
      'parameters': {'gain': 1.0},
      'meters': {'gainReductionDb': 6.0, 'inputLevel': 0.72},
    });
    await pumpSlot(tester, device);

    expect(find.text('GR'), findsOneWidget);
    expect(find.text('IN'), findsOneWidget);
    expect(find.text('Trim'), findsOneWidget);
  });
}
