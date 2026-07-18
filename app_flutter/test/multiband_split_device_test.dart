import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/devices/frequency/mb_split_layout.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mb_split_3 snapshot parses crossovers, gains and bands', () {
    final mb = DeviceSnapshot.fromMap({
      'id': 'mb-1',
      'type': 'mb_split_3',
      'bypass': false,
      'parameters': {
        'band0Gain': 0.8,
        'band1Gain': 1.2,
        'crossover0': 250,
        'crossover1': 2500,
      },
      'outputPanel': {'outputMix': 0.7, 'outputWidth': 0.9},
      'bands': [
        {
          'devices': [
            {
              'id': 'eq-lo',
              'type': 'four_band_eq',
              'bypass': false,
              'parameters': const {},
            }
          ],
        },
        {'devices': const []},
        {'devices': const []},
      ],
    }) as MultibandSplitDeviceSnapshot;

    expect(mb.bandCount, 3);
    expect(mb.crossoverHz, [250, 2500]);
    expect(mb.bandGainAt(0), 0.8);
    expect(mb.bandGainAt(1), 1.2);
    expect(mb.outputMix, 0.7);
    expect(mb.outputWidth, 0.9);
    expect(mb.bandDevices(0).single.id, 'eq-lo');
    expect(DeviceStripMetrics.outputPanelWidthFor('mb_split_3'), 64);
    expect(MbSplitLayout.designWidth(3), 276);
  });

  test('withParameter updates crossover and exclusive-ish gain', () {
    const mb = MultibandSplitDeviceSnapshot(
      id: 'mb-2',
      type: 'mb_split_2',
      bypassed: false,
      bandCount: 2,
      crossoverHz: [1000],
    );
    final withXo = mb.withParameter('crossover0', 800);
    expect(withXo.crossoverAt(0), 800);
    final withGain = withXo.withParameter('band1Gain', 1.5);
    expect(withGain.bandGainAt(1), 1.5);
    final withMix = withGain.withParameter('outputMix', 0.4);
    expect(withMix.outputMix, 0.4);
  });

  test('project snapshot finds nested multiband child', () {
    final child = DeviceSnapshot.fromMap({
      'id': 'fx-1',
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
            MultibandSplitDeviceSnapshot(
              id: 'mb-1',
              type: 'mb_split_2',
              bypassed: false,
              bandCount: 2,
              crossoverHz: const [1000],
              bands: [
                [child],
                const [],
              ],
            ),
          ],
          midiClips: const [],
          sampleClips: const [],
        ),
      ],
      lfos: const [],
      modEdges: const [],
    );

    expect(snapshot.deviceById('fx-1'), isNotNull);
  });
}
