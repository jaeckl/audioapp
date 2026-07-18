import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lr_split snapshot parses branch gains, solos and child devices', () {
    final split = DeviceSnapshot.fromMap({
      'id': 'split-1',
      'type': 'lr_split',
      'bypass': false,
      'parameters': {
        'branch0Gain': 0.5,
        'branch1Gain': 1.5,
        'branch0Solo': 1,
        'branch1Solo': 0,
      },
      'branches': [
        {
          'devices': [
            {
              'id': 'osc-left',
              'type': 'simple_oscillator',
              'bypass': false,
              'parameters': {'frequency': 220.0}
            }
          ],
        },
        {
          'devices': [
            {
              'id': 'osc-right',
              'type': 'simple_oscillator',
              'bypass': false,
              'parameters': {'frequency': 440.0}
            }
          ],
        },
      ],
    }) as SplitDeviceSnapshot;

    expect(split.isMidSide, isFalse);
    expect(split.branch0Gain, 0.5);
    expect(split.branch1Gain, 1.5);
    expect(split.branch0Solo, isTrue);
    expect(split.branch1Solo, isFalse);
    expect(split.branch0.single.id, 'osc-left');
    expect(split.branch1.single.id, 'osc-right');
    expect(DeviceStripMetrics.outputPanelWidthFor('lr_split'), 30);
  });

  test('ms_split snapshot reports mid/side and defaults empty branches', () {
    final split = DeviceSnapshot.fromMap({
      'id': 'split-2',
      'type': 'ms_split',
      'bypass': false,
      'parameters': const {},
    }) as SplitDeviceSnapshot;

    expect(split.isMidSide, isTrue);
    expect(split.branch0Gain, 1);
    expect(split.branch1Gain, 1);
    expect(split.branch0, isEmpty);
    expect(split.branch1, isEmpty);
  });

  test('withParameter updates gain and exclusive solo optimistically', () {
    const split = SplitDeviceSnapshot(id: 'split-3', type: 'lr_split', bypassed: false);
    final withGain = split.withParameter('branch0Gain', 1.75);
    expect(withGain.branch0Gain, 1.75);
    final withSolo = split.withParameter('branch1Solo', 1.0);
    expect(withSolo.branch1Solo, isTrue);
    expect(withSolo.branch0Solo, isFalse);
    final switched = withSolo.withParameter('branch0Solo', 1.0);
    expect(switched.branch0Solo, isTrue);
    expect(switched.branch1Solo, isFalse);
  });

  test('project snapshot finds and updates split branch child devices', () {
    final child = DeviceSnapshot.fromMap({
      'id': 'osc-1',
      'type': 'simple_oscillator',
      'bypass': false,
      'parameters': {'frequency': 440.0}
    });
    final snapshot = _projectWithDevices([
      const SplitDeviceSnapshot(id: 'split-1', type: 'ms_split', bypassed: false)
          .copyWith(branch1: [child]),
    ]);

    expect(snapshot.deviceById('osc-1'), isNotNull);

    final updated = snapshot.withDeviceParam('osc-1', 'frequency', 880.0);
    final split = updated.tracks.single.devices.single as SplitDeviceSnapshot;
    final osc = split.branch1.single as OscillatorDeviceSnapshot;
    expect(osc.frequencyHz, 880.0);
  });
}

ProjectSnapshot _projectWithDevices(List<DeviceSnapshot> devices) {
  return ProjectSnapshot(
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
        devices: devices,
        midiClips: const [],
        sampleClips: const [],
      ),
    ],
    lfos: const [],
    modEdges: const [],
  );
}
