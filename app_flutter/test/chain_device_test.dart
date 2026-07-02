import 'package:audioapp/bridge/device_snapshot.dart';
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
}
