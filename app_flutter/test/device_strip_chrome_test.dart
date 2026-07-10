import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_chrome.dart';
import 'package:audioapp/features/device_strip/device_strip_chrome_panels.dart';
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

    test('delay omits input chrome and keeps stereo mix output width', () {
      expect(DeviceStripChrome.inputWidth('delay'), 0);
      expect(DeviceStripChrome.hasInputPanel('delay'), isFalse);
      expect(DeviceStripChrome.outputWidth('delay'), 64);
    });

    test('chorus omits input chrome and keeps stereo mix output width', () {
      expect(DeviceStripChrome.inputWidth('chorus'), 0);
      expect(DeviceStripChrome.hasInputPanel('chorus'), isFalse);
      expect(DeviceStripChrome.outputWidth('chorus'), 64);
    });

    test('reverb omits input chrome and keeps stereo mix output width', () {
      expect(DeviceStripChrome.inputWidth('reverb'), 0);
      expect(DeviceStripChrome.hasInputPanel('reverb'), isFalse);
      expect(DeviceStripChrome.outputWidth('reverb'), 64);
    });

    test('phaser omits input chrome and keeps stereo mix output width', () {
      expect(DeviceStripChrome.inputWidth('phaser'), 0);
      expect(DeviceStripChrome.hasInputPanel('phaser'), isFalse);
      expect(DeviceStripChrome.outputWidth('phaser'), 64);
    });

    test('mono drums use drum output width without input', () {
      expect(DeviceStripChrome.inputWidth('kick_generator'), 0);
      expect(DeviceStripChrome.outputWidth('kick_generator'), 64);
    });

    test('analysis devices keep empty output chrome width', () {
      expect(DeviceStripChrome.outputWidth('oscilloscope'), 64);
      expect(DeviceStripChrome.outputWidth('spectrum_analyzer'), 64);
    });
  });

  testWidgets('synth slot shows pan and gain on stereo output rail',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-synth',
      'type': 'subtractive_synth',
      'parameters': {'gain': 0.8, 'pan': 0.25},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('Gain'), findsOneWidget);
    expect(find.text('Pan'), findsOneWidget);
  });

  testWidgets('subtractive synth signal-flow tabs fit the strip',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-synth-tabs',
      'type': 'subtractive_synth',
      'parameters': <String, Object>{},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('OSC 1'), findsOneWidget);
    expect(find.text('OSC 2'), findsOneWidget);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Cutoff'), findsOneWidget);
    expect(find.byIcon(Icons.piano), findsOneWidget);
    expect(find.text('FM'), findsOneWidget);
    expect(find.text('Key'), findsNothing);

    await tester.tap(find.text('Amp'));
    await tester.pumpAndSettle();
    expect(find.text('AMP ENVELOPE'), findsNothing);
    expect(find.text('PERFORMANCE'), findsOneWidget);
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

  testWidgets('delay slot has two-control Stereo Mix Output rail',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-delay',
      'type': 'delay',
      'parameters': {'timeMs': 250.0, 'feedback': 0.4},
      'outputPanel': {'outputMix': 0.5, 'outputWidth': 0.75},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('IN'), findsNothing);
    expect(find.text('OUT'), findsOneWidget);
    expect(find.text('Width'), findsOneWidget);
    expect(find.text('Mix'), findsOneWidget);
  });

  testWidgets('phaser slot omits the generic input panel', (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-phaser',
      'type': 'phaser',
      'parameters': {
        'depth': .5,
        'rateHz': .8,
        'feedback': .3,
        'centreFrequencyHz': 1000.0,
      },
      'outputPanel': {'outputMix': .5, 'outputWidth': 1.0},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('IN'), findsNothing);
    expect(find.text('OUT'), findsOneWidget);
    expect(find.text('Centre'), findsOneWidget);
    expect(find.text('MOTION'), findsOneWidget);
    expect(find.text('RESPONSE'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('phaser-waveform-selector')), findsOneWidget);
    await tester.tap(find.text('RESPONSE'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverb slot uses Version C tabs and header actions',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-reverb',
      'type': 'reverb',
      'parameters': {'modeMorph': 2.0, 'decay': .56},
      'outputPanel': {'outputMix': .35, 'outputWidth': 1.0},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('TAIL'), findsOneWidget);
    expect(find.text('TONE'), findsOneWidget);
    expect(find.text('MOD'), findsOneWidget);
    expect(find.byKey(const ValueKey('reverb-header-mode')), findsOneWidget);
    expect(find.byKey(const ValueKey('reverb-freeze')), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    expect(tester.widget<Text>(find.text('TAIL')).style?.fontSize, 11);
    expect(tester.widget<Icon>(find.byIcon(Icons.multiline_chart)).size, 15);
    expect(
        find.byKey(const ValueKey('reverb-parameter-column')), findsOneWidget);
    await tester.tap(find.text('TONE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MOD'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('oscilloscope slot shows empty output chrome rail',
      (tester) async {
    final device = DeviceSnapshot.fromMap({
      'id': 'dev-scope',
      'type': 'oscilloscope',
      'parameters': <String, Object>{},
    });
    await pumpSlot(tester, device: device);

    expect(find.text('Gain'), findsNothing);
    expect(find.text('Pan'), findsNothing);
    expect(find.byType(EmptyChromeOutputPanel), findsOneWidget);
  });
}
