import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final kickDevice = DeviceSnapshot.fromMap({
    'id': 'dev-kick',
    'type': 'kick_generator',
    'parameters': {
      'gain': 0.8,
      'kickModel': 0.0,
      'kickPitch': 0.55,
      'kickPunch': 0.6,
      'kickDecay': 0.5,
      'kickClick': 0.35,
      'kickTone': 0.5,
      'kickVelocity': 1.0,
    },
  });

  Future<void> pumpKickSlot(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: DeviceStripMetrics.fullscreenHeight,
            child: DeviceStripSlot(
              track: TrackSnapshot(
                id: 'track-1',
                name: 'Track 1',
                devices: [kickDevice],
                midiClips: [],
                sampleClips: [],
              ),
              device: kickDevice,
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

  test('kick design width is wider bench layout', () {
    expect(DeviceStripMetrics.designWidthFor('kick_generator'), 480);
  });

  testWidgets('kick bench shows all timbre knobs without tabs', (tester) async {
    await pumpKickSlot(tester);

    expect(find.text('Pitch'), findsOneWidget);
    expect(find.text('Punch'), findsOneWidget);
    expect(find.text('Tone'), findsOneWidget);
    expect(find.text('Click'), findsOneWidget);
    expect(find.text('Decay'), findsOneWidget);
    expect(find.text('Body'), findsNothing);
    expect(find.text('Trans'), findsNothing);
    expect(find.text('Amp'), findsNothing);
  });

  testWidgets('kick bench shows model segment with 808 selected', (tester) async {
    await pumpKickSlot(tester);

    expect(find.text('808'), findsWidgets);
    expect(find.text('909'), findsOneWidget);
    expect(find.text('Analog'), findsOneWidget);
    expect(find.text('Mono · 808'), findsOneWidget);
  });

  testWidgets('kick velocity is on output rail not card body', (tester) async {
    await pumpKickSlot(tester);

    expect(find.text('Vel sens'), findsOneWidget);
    expect(find.text('Velocity'), findsNothing);
  });
}
