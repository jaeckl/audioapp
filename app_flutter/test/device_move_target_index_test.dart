import 'package:audioapp/features/device_strip/device_chain_separator.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

const _track = TrackSnapshot(
  id: 'track-1',
  name: 'Devices',
  devices: [
    DeviceSnapshot(
      id: 'dev-a',
      type: 'simple_oscillator',
      bypassed: false,
      parameters: {},
    ),
    DeviceSnapshot(
      id: 'dev-b',
      type: 'compressor',
      bypassed: false,
      parameters: {},
    ),
    TrackGainDeviceSnapshot(
      id: 'dev-gain',
      type: 'track_gain',
      bypassed: false,
      parameters: {'gain': 1.0},
      gain: 1.0,
      pan: 0.5,
    ),
  ],
  midiClips: [],
  sampleClips: [],
);

void main() {
  test('deviceMoveTargetIndex maps visible separator to engine slot', () {
    expect(deviceMoveTargetIndex(_track, -1), 0);
    expect(deviceMoveTargetIndex(_track, 0), 1);
    expect(deviceMoveWouldBeNoOp(1, 0), isTrue);
    expect(deviceMoveWouldBeNoOp(1, 1), isTrue);
    expect(deviceMoveWouldBeNoOp(0, 1), isFalse);
  });
}
