import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_chrome.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrackSnapshot trackFor(DeviceSnapshot device) => TrackSnapshot(
        id: 'track-1',
        name: 'Track 1',
        devices: [device],
        midiClips: [],
        sampleClips: [],
      );

  Future<void> pumpSlot(
    WidgetTester tester, {
    required DeviceSnapshot device,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: DeviceStripMetrics.fullscreenHeight,
            child: DeviceStripSlot(
              track: trackFor(device),
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
  }

  group('DeviceStripChrome registry', () {
    test('stereo synth uses stereo output width', () {
      expect(DeviceStripChrome.outputWidth('subtractive_synth'), 64);
      expect(DeviceStripChrome.inputWidth('subtractive_synth'), 0);
    });

    test('dynamics types allocate input and output panels', () {
      expect(DeviceStripChrome.inputWidth('compressor'), 64);
      expect(DeviceStripChrome.outputWidth('compressor'), 64);
      expect(DeviceStripChrome.hasInputPanel('gate'), isTrue);
    });

    test('mono drums use drum output width without input', () {
      expect(DeviceStripChrome.inputWidth('kick_generator'), 0);
      expect(DeviceStripChrome.outputWidth('kick_generator'), 64);
    });
  });

  testWidgets('synth slot shows pan and gain on stereo output rail', (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-synth',
      'type': 'subtractive_synth',
      'parameters': {'gain': 0.8, 'pan': 0.25},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('Gain'), findsOneWidget);
    expect(find.text('Pan'), findsOneWidget);
  });

  testWidgets('kick slot shows vel sens without pan', (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-kick',
      'type': 'kick_generator',
      'parameters': {'gain': 0.8, 'kickVelocity': 0.75},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('Vel sens'), findsOneWidget);
    expect(find.text('Gain'), findsOneWidget);
    expect(find.text('Pan'), findsNothing);
  });

  testWidgets('compressor slot includes dynamics input panel', (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-comp',
      'type': 'compressor',
      'parameters': {'gain': 1.0, 'compThreshold': 0.5},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('IN'), findsOneWidget);
    expect(find.text('GR'), findsOneWidget);
    expect(find.text('Pan'), findsNothing);
  });
}
