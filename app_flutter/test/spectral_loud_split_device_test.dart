import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/devices/frequency/spectral_loud_split_layout.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/meter_subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spectral_loud_split snapshot parses thresholds, bands, pre/post, mix', () {
    final sl = DeviceSnapshot.fromMap({
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

  test('project snapshot finds nested spectral loud child', () {
    final child = DeviceSnapshot.fromMap({
      'id': 'fx-pre',
      'type': 'filter',
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
              preFxDevices: [child],
            ),
          ],
          midiClips: const [],
          sampleClips: const [],
        ),
      ],
      lfos: const [],
      modEdges: const [],
    );
    expect(snapshot.deviceById('fx-pre'), isNotNull);
  });
}
