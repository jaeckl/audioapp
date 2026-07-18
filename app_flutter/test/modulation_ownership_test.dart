import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_modulator_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device panels only receive their owned modulators', () {
    const modulators = [
      LfoSnapshot(id: 1, ownerDeviceId: 'device-a'),
      LfoSnapshot(id: 2, ownerDeviceId: 'device-b'),
    ];

    expect(
      modulatorsForDevicePanel(
        modulators: modulators,
        edges: const [],
        deviceId: 'device-a',
      ).map((modulator) => modulator.id),
      [1],
    );
    expect(
      modulatorsForDevicePanel(
        modulators: modulators,
        edges: const [],
        deviceId: 'device-b',
      ).map((modulator) => modulator.id),
      [2],
    );
  });

  test('legacy modulators are visible only on devices they target', () {
    const modulators = [LfoSnapshot(id: 7)];
    const edges = [
      ModulationEdgeSnapshot(
        lfoId: 7,
        deviceId: 'device-b',
        paramId: 'drive',
      ),
    ];

    expect(
      modulatorsForDevicePanel(
        modulators: modulators,
        edges: edges,
        deviceId: 'device-a',
      ),
      isEmpty,
    );
    expect(
      modulatorsForDevicePanel(
        modulators: modulators,
        edges: edges,
        deviceId: 'device-b',
      ).single.id,
      7,
    );
  });

  test('snapshot parsing retains modulator ownership', () {
    final modulator = LfoSnapshot.fromMap({
      'id': 3,
      'type': 'lfo',
      'ownerDeviceId': 'device-a',
    });
    expect(modulator.ownerDeviceId, 'device-a');
    expect(modulator.copyWith(rate: 2.0).ownerDeviceId, 'device-a');
  });
}
