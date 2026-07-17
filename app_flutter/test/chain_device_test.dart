import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chain snapshot preserves controls and child devices', () {
    final chain = DeviceSnapshot.fromMap({
      'id': 'chain-1',
      'type': 'device_chain',
      'bypass': false,
      'parameters': {'chainMix': 0.6, 'chainGain': 1.25},
      'devices': [
        {
          'id': 'osc-1',
          'type': 'simple_oscillator',
          'bypass': false,
          'parameters': {'frequency': 440.0}
        }
      ],
    }) as ChainDeviceSnapshot;
    expect(chain.mix, 0.6);
    expect(chain.chainGain, 1.25);
    expect(chain.devices.single.id, 'osc-1');
    expect(DeviceStripMetrics.designWidthFor('device_chain'), 82);
    expect(DeviceStripMetrics.outputPanelWidthFor('device_chain'),
        DeviceStripMetrics.toolRailWidth);
  });

  test('project snapshot finds and updates chain child devices', () {
    final child = DeviceSnapshot.fromMap({
      'id': 'osc-1',
      'type': 'simple_oscillator',
      'bypass': false,
      'parameters': {'frequency': 440.0}
    });
    final snapshot = _projectWithDevices([
      ChainDeviceSnapshot(id: 'chain-1', bypassed: false, devices: [child]),
    ]);

    expect(snapshot.deviceById('osc-1'), isNotNull);

    final updated = snapshot.withDeviceParam('osc-1', 'frequency', 880.0);
    final chain = updated.tracks.single.devices.single as ChainDeviceSnapshot;
    final osc = chain.devices.single as OscillatorDeviceSnapshot;
    expect(osc.frequencyHz, 880.0);
  });

  test('project snapshot finds and updates drum pad child devices', () {
    final child = DeviceSnapshot.fromMap({
      'id': 'sampler-1',
      'type': 'simple_sampler',
      'bypass': false,
      'parameters': {'gain': 0.5, 'sampleId': ''}
    });
    final snapshot = _projectWithDevices([
      DrumMachineDeviceSnapshot(
        id: 'drum-1',
        bypassed: false,
        pads: [
          DrumPadSnapshot(note: 36, devices: [child]),
        ],
      ),
    ]);

    expect(snapshot.deviceById('sampler-1'), isNotNull);

    final updated = snapshot.withDeviceParam('sampler-1', 'gain', 0.75);
    final machine =
        updated.tracks.single.devices.single as DrumMachineDeviceSnapshot;
    final sampler = machine.pads.single.devices.single as SamplerDeviceSnapshot;
    expect(sampler.gain, 0.75);
  });

  test('distortion stable parameter ids update optimistic knob values', () {
    final distortion = DeviceSnapshot.fromMap({
      'id': 'dist-1',
      'type': 'distortion',
      'bypass': false,
      'parameters': {'drive': 0.2, 'tone': 0.3},
    }) as DistortionDeviceSnapshot;

    expect(distortion.withParameter('distDrive', 0.8).distDrive, 0.8);
    expect(distortion.withParameter('distTone', 0.9).distTone, 0.9);
  });

  test('drum machine output strip updates optimistically', () {
    final machine = DeviceSnapshot.fromMap({
      'id': 'drum-1',
      'type': 'drum_machine',
      'bypass': false,
      'outputPanel': {'gain': 0.7, 'pan': 0.4},
      'pads': const [],
    }) as DrumMachineDeviceSnapshot;

    expect(machine.gain, 0.7);
    expect(machine.pan, 0.4);
    expect(machine.withParameter('gain', 0.25).gain, 0.25);
    expect(machine.withParameter('pan', 0.75).pan, 0.75);
  });

  test('effect output panels and stable tremolo ids survive snapshots', () {
    final distortion = DeviceSnapshot.fromMap({
      'id': 'dist-1',
      'type': 'distortion',
      'bypass': false,
      'parameters': {'drive': 0.5, 'tone': 0.5},
      'outputPanel': {'outputMix': 0.35, 'outputWidth': 0.65},
    }) as DistortionDeviceSnapshot;
    final tremolo = DeviceSnapshot.fromMap({
      'id': 'trem-1',
      'type': 'tremolo',
      'bypass': false,
      'parameters': {'depth': 0.2, 'rateHz': 2.0, 'shape': 0.0},
      'outputPanel': {'outputMix': 0.4, 'outputWidth': 0.7},
    }) as TremoloDeviceSnapshot;

    expect(distortion.outputMix, 0.35);
    expect(distortion.outputWidth, 0.65);
    expect(tremolo.outputMix, 0.4);
    expect(tremolo.outputWidth, 0.7);
    expect(tremolo.withParameter('tremDepth', 0.8).tremDepth, 0.8);
    expect(tremolo.withParameter('tremRate', 12.0).tremRate, 12.0);
    expect(tremolo.withParameter('tremShape', 1.0).tremShape, 1.0);
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
