import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/granular_device_panel.dart';
import 'package:audioapp/features/device_strip/device_preset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('granular phase-two parameters parse and update', () {
    final device = DeviceSnapshot.fromMap({
      'id': 'grain-1',
      'type': 'granular_formant_synth',
      'parameters': {
        'regionStart': .2,
        'regionEnd': .8,
        'attack': .1,
        'release': .4,
        'spread': .7,
        'formX': .8,
        'formY': .3,
      },
    }) as GranularDeviceSnapshot;
    expect(device.regionStart, .2);
    expect(device.regionEnd, .8);
    expect(device.attack, .1);
    expect(device.release, .4);
    expect(device.spread, .7);
    expect(device.formX, .8);
    expect(device.formY, .3);
    expect(device.sampleId, 'sample_form_source');
    expect(device.withParameter('spread', .25).spread, .25);
  });

  test('granular factory preset selects a stable demo sample', () {
    final preset = DevicePresetStore.find(
      'granular_formant_synth',
      'preset:grain-glass-choir',
    );
    expect(preset, isNotNull);
    expect(preset!.stringParams['sampleId'], 'demo_form_lost_choir');
    expect(preset.params['grainSize'], .7);
    expect(preset.params['formX'], .88);
  });

  testWidgets('granular form page stays inside device height', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: GranularDevicePanel.designWidth,
          height: 240,
          child: GranularDevicePanel(
            device: const GranularDeviceSnapshot(
              id: 'grain-1',
              bypassed: false,
            ),
            sample: const SampleLibraryEntrySnapshot(
              id: 'sample-1',
              name: 'Voice',
              source: 'test',
              durationBeats: 4,
              waveformPeaks: [0, .5, -.5, .25],
            ),
            tab: 2,
            playing: false,
            playheadBeat: 0,
            onChanged: (_, __) {},
          ),
        ),
      ),
    ));
    expect(find.text('Spread'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final tab in [0, 1]) {
    testWidgets('granular tab $tab preview stays inside device height',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: GranularDevicePanel.designWidth,
            height: 240,
            child: GranularDevicePanel(
              device: const GranularDeviceSnapshot(
                id: 'grain-1',
                bypassed: false,
                sampleId: 'sample-1',
              ),
              sample: const SampleLibraryEntrySnapshot(
                id: 'sample-1',
                name: 'Voice',
                source: 'test',
                durationBeats: 4,
                waveformPeaks: [0, .5, -.5, .25],
              ),
              tab: tab,
              playing: true,
              playheadBeat: 1,
              onChanged: (_, __) {},
            ),
          ),
        ),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
