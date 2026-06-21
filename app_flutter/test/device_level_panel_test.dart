import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_level_panel.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final device = DeviceSnapshot.fromMap({
    'id': 'dev-1',
    'type': 'simple_sampler',
    'parameters': {'gain': 0.8, 'pan': 0.25, 'sampleId': ''},
  });

  test('DeviceLevelPanel formats pan labels', () {
    expect(DeviceLevelPanel.formatPan(0.5), 'C');
    expect(DeviceLevelPanel.formatPan(0.0), 'L100');
    expect(DeviceLevelPanel.formatPan(1.0), 'R100');
    expect(DeviceLevelPanel.formatGain(0.8), '80%');
  });

  testWidgets('DeviceStripSlot shows level panel with gain and pan knobs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: DeviceStripMetrics.fullscreenHeight,
            child: DeviceStripSlot(
              track: TrackSnapshot(
                id: 'track-1',
                name: 'Track 1',
                devices: [device],
                midiClips: [],
                sampleClips: [],
              ),
              device: device,
              sample: null,
              bpm: 120,
              playing: false,
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

    expect(find.text('Gain'), findsOneWidget);
    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('L50'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
  });
}
