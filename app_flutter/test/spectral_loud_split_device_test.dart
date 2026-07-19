import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/devices/frequency/spectral_loud_split_layout.dart';
import 'package:audioapp/features/device_strip/device_strip_chrome.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:audioapp/features/device_strip/device_strip_theme.dart';
import 'package:audioapp/features/device_strip/meter_subscription.dart';
import 'package:audioapp/features/device_strip/spectral_loud_split_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SpectralLoudSplitDeviceSnapshot baseDevice() =>
      DeviceSnapshot.fromMap({
        'id': 'sl-1',
        'type': 'spectral_loud_split',
        'bypass': false,
        'parameters': {
          'highDb': -12,
          'lowDb': -36,
          'band0Gain': 0.9,
          'band1Gain': 1.1,
          'band2Gain': 0.5,
          'band0Solo': 1,
        },
        'outputPanel': {'type': 'pre_post_mix', 'outputMix': 0.65},
        'bands': [
          {
            'devices': [
              {
                'id': 'eq-loud',
                'type': 'four_band_eq',
                'bypass': false,
                'parameters': const {},
              }
            ],
          },
          {'devices': const []},
          {'devices': const []},
        ],
        'preFx': {
          'devices': [
            {
              'id': 'pre-comp',
              'type': 'compressor',
              'bypass': false,
              'parameters': const {},
            }
          ],
        },
        'postFx': {
          'devices': [
            {
              'id': 'post-delay',
              'type': 'delay',
              'bypass': false,
              'parameters': const {},
            }
          ],
        },
      }) as SpectralLoudSplitDeviceSnapshot;

  test('spectral_loud_split snapshot parses thresholds, bands, pre/post, mix',
      () {
    final sl = baseDevice();
    expect(sl.highDb, -12);
    expect(sl.lowDb, -36);
    expect(sl.bandGainAt(0), 0.9);
    expect(sl.bandGainAt(1), 1.1);
    expect(sl.bandSoloAt(0), isTrue);
    expect(sl.outputMix, 0.65);
    expect(sl.bandDevices(0).single.id, 'eq-loud');
    expect(sl.preFxDevices.single.id, 'pre-comp');
    expect(sl.postFxDevices.single.id, 'post-delay');
    expect(DeviceStripMetrics.outputPanelWidthFor('spectral_loud_split'), 85);
    expect(DeviceStripMetrics.designWidthFor('spectral_loud_split'),
        SpectralLoudSplitLayout.designWidth);
    expect(SpectralLoudSplitLayout.controlsWidth, 180);
    expect(SpectralLoudSplitLayout.designWidth, 398);
    expect(SpectralLoudSplitLayout.colGap, 6);
    expect(MeterSubscription.publishesLiveMeters('spectral_loud_split'), isTrue);
  });

  test('withParameter updates thresholds, exclusive solo, mix', () {
    const sl = SpectralLoudSplitDeviceSnapshot(
      id: 'sl-2',
      type: 'spectral_loud_split',
      bypassed: false,
    );
    final withHigh = sl.withParameter('highDb', -10);
    expect(withHigh.highDb, -10);
    final withSolo = withHigh.withParameter('band2Solo', 1);
    expect(withSolo.bandSoloAt(2), isTrue);
    expect(withSolo.bandSoloAt(0), isFalse);
    final withMix = withSolo.withParameter('outputMix', 0.3);
    expect(withMix.outputMix, 0.3);
  });

  test('project snapshot finds nested spectral loud child in band/pre/post', () {
    final bandChild = DeviceSnapshot.fromMap({
      'id': 'fx-band',
      'type': 'four_band_eq',
      'bypass': false,
      'parameters': const {},
    });
    final preChild = DeviceSnapshot.fromMap({
      'id': 'fx-pre',
      'type': 'filter',
      'bypass': false,
      'parameters': const {},
    });
    final postChild = DeviceSnapshot.fromMap({
      'id': 'fx-post',
      'type': 'delay',
      'bypass': false,
      'parameters': const {},
    });
    final snapshot = ProjectSnapshot(
      bpm: 120,
      selectedTrackId: 'track-1',
      playheadBeats: 0,
      playing: false,
      loopEnabled: true,
      recordArmed: false,
      master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
      samples: const [],
      tracks: [
        TrackSnapshot(
          id: 'track-1',
          name: 'Track 1',
          devices: [
            SpectralLoudSplitDeviceSnapshot(
              id: 'sl-1',
              type: 'spectral_loud_split',
              bypassed: false,
              bands: [
                [bandChild],
                const [],
                const [],
              ],
              preFxDevices: [preChild],
              postFxDevices: [postChild],
            ),
          ],
          midiClips: const [],
          sampleClips: const [],
        ),
      ],
      lfos: const [],
      modEdges: const [],
    );
    expect(snapshot.deviceById('fx-band'), isNotNull);
    expect(snapshot.deviceById('fx-pre'), isNotNull);
    expect(snapshot.deviceById('fx-post'), isNotNull);
  });

  test('band highlight colors match theme tokens used by toggles', () {
    expect(DeviceStripTheme.spectralLoudBandColor(0),
        DeviceStripTheme.spectralLoudBandLoud);
    expect(DeviceStripTheme.spectralLoudBandColor(1),
        DeviceStripTheme.spectralLoudBandMid);
    expect(DeviceStripTheme.spectralLoudBandColor(2),
        DeviceStripTheme.spectralLoudBandQuiet);
    expect(DeviceStripTheme.spectralLoudBandColor(0),
        isNot(DeviceStripTheme.spectralLoudBandColor(1)));
  });

  test('chrome width uses pre/post mix output panel', () {
    expect(DeviceStripChrome.outputWidth('spectral_loud_split'), 85);
    expect(DeviceStripChrome.inputWidth('spectral_loud_split'), 0);
  });

  TrackSnapshot trackFor(DeviceSnapshot device) => TrackSnapshot(
        id: 'track-1',
        name: 'Track 1',
        devices: [device],
        midiClips: [],
        sampleClips: [],
      );

  test('open nesting: nested spectral hosts parse containers in PRE/band/POST',
      () {
    final nested = DeviceSnapshot.fromMap({
      'id': 'sl-nest',
      'type': 'spectral_loud_split',
      'bypass': false,
      'parameters': const {},
      'bands': [
        {
          'devices': [
            {
              'id': 'band-chain',
              'type': 'device_chain',
              'bypass': false,
              'parameters': const {},
              'devices': [
                {
                  'id': 'band-delay',
                  'type': 'delay',
                  'bypass': false,
                  'parameters': const {},
                }
              ],
            }
          ],
        },
        {'devices': const []},
        {'devices': const []},
      ],
      'preFx': {
        'devices': [
          {
            'id': 'pre-mb',
            'type': 'mb_split_3',
            'bypass': false,
            'parameters': const {},
            'bands': [
              {
                'devices': [
                  {
                    'id': 'pre-fx',
                    'type': 'filter',
                    'bypass': false,
                    'parameters': const {},
                  }
                ],
              },
              {'devices': const []},
              {'devices': const []},
            ],
          }
        ],
      },
      'postFx': {
        'devices': [
          {
            'id': 'post-chain',
            'type': 'device_chain',
            'bypass': false,
            'parameters': const {},
            'devices': const [],
          }
        ],
      },
    }) as SpectralLoudSplitDeviceSnapshot;

    expect(nested.bandDevices(0).single.type, 'device_chain');
    expect(nested.preFxDevices.single.type, 'mb_split_3');
    expect(nested.postFxDevices.single.type, 'device_chain');

    final snap = ProjectSnapshot(
      bpm: 120,
      selectedTrackId: 'track-1',
      playheadBeats: 0,
      playing: false,
      loopEnabled: true,
      recordArmed: false,
      master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
      samples: const [],
      tracks: [trackFor(nested)],
      lfos: const [],
      modEdges: const [],
    );
    expect(snap.deviceById('band-delay'), isNotNull);
    expect(snap.deviceById('pre-fx'), isNotNull);
    expect(snap.deviceById('post-chain'), isNotNull);
  });

  testWidgets('panel shows Loud/Mid/Quiet rows and preview handles',
      (tester) async {
    final device = baseDevice();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: SpectralLoudSplitLayout.designWidth,
            height: 220,
            child: SpectralLoudSplitPanel(
              device: device,
              onChanged: (_, __) {},
              onToggleBand: (_) {},
              expandedBands: {0},
              spectrum: List<double>.filled(24, 0.4),
              bandLevels: const [0.5, 0.2, 0.1],
            ),
          ),
        ),
      ),
    );
    // Panel may host repeating meter/preview animations — settle never ends.
    await tester.pump();

    expect(find.text('LOUD'), findsOneWidget);
    expect(find.text('MID'), findsOneWidget);
    expect(find.text('QUIET'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(3));
    expect(find.text('Gain'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('slot chrome shows PRE FX, POST FX and Mix', (tester) async {
    final device = baseDevice();
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
    await tester.pump();

    expect(find.text('OUT'), findsOneWidget);
    expect(find.text('PRE FX'), findsOneWidget);
    expect(find.text('POST FX'), findsOneWidget);
    expect(find.text('Mix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
