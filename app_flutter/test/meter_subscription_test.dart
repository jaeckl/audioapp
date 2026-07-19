import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_layout.dart';
import 'package:audioapp/features/device_strip/device_strip_metrics.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:audioapp/features/device_strip/meter_subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DeviceSnapshot _device(String id, String type) => DeviceSnapshot.fromMap({
      'id': id,
      'type': type,
      'parameters': const {},
    });

void main() {
  test('publishesLiveMeters covers analysis, dynamics and split types', () {
    expect(MeterSubscription.publishesLiveMeters('oscilloscope'), isTrue);
    expect(MeterSubscription.publishesLiveMeters('compressor'), isTrue);
    expect(MeterSubscription.publishesLiveMeters('lr_split'), isTrue);
    expect(MeterSubscription.publishesLiveMeters('ms_split'), isTrue);
    expect(MeterSubscription.publishesLiveMeters('mb_split_2'), isTrue);
    expect(MeterSubscription.publishesLiveMeters('spectral_loud_split'), isTrue);
    expect(MeterSubscription.publishesLiveMeters('simple_oscillator'), isFalse);
  });

  testWidgets('visibleMeterDeviceIds respects horizontal scroll viewport',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    final devices = [
      _device('first', 'oscilloscope'),
      _device('second', 'compressor'),
      _device('third', 'spectrum_analyzer'),
    ];
    final track = TrackSnapshot(
      id: 't1',
      name: 'Track 1',
      devices: devices,
      midiClips: const [],
      sampleClips: const [],
    );
    const density = DeviceStripSlotDensity.strip;

    double slotStart(int index) {
      var x = 8.0;
      for (var i = 0; i < index; i++) {
        x += DeviceChainLayout.slotWidthFor(devices[i], density) +
            DeviceStripMetrics.separatorWidth;
      }
      return x;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 240,
          height: 120,
          child: ListView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            children: const [
              SizedBox(width: 2400, height: 80),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final atStart = MeterSubscription.visibleMeterDeviceIds(
      track: track,
      density: density,
      scrollController: scroll,
      viewportWidth: 240,
    );
    expect(atStart, contains('first'));
    expect(atStart, isNot(contains('third')));

    scroll.jumpTo(slotStart(2));
    await tester.pump();

    final atThird = MeterSubscription.visibleMeterDeviceIds(
      track: track,
      density: density,
      scrollController: scroll,
      viewportWidth: 240,
    );
    expect(atThird, contains('third'));
    expect(atThird, isNot(contains('first')));
  });

  testWidgets('visibleMeterDeviceIds includes nested chain compressor in viewport',
      (tester) async {
    const density = DeviceStripSlotDensity.strip;
    final chain = ChainDeviceSnapshot(
      id: 'chain-host',
      bypassed: false,
      devices: [
        _device('nested-comp', 'compressor'),
      ],
    );
    final track = TrackSnapshot(
      id: 't1',
      name: 'Track 1',
      devices: [
        _device('osc', 'simple_oscillator'),
        chain,
      ],
      midiClips: const [],
      sampleClips: const [],
    );

    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 120,
          child: ListView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            children: const [
              SizedBox(width: 4000, height: 80),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    var x = 8.0;
    for (final device in track.visibleDevices) {
      x += DeviceChainLayout.slotWidthFor(device, density);
      if (device.id == 'chain-host') break;
      x += DeviceStripMetrics.separatorWidth;
    }
    const chromeWidth = 2.0 + 18.0 + 20.0;
    scroll.jumpTo(x + chromeWidth);
    await tester.pump();

    final ids = MeterSubscription.visibleMeterDeviceIds(
      track: track,
      density: density,
      scrollController: scroll,
      viewportWidth: 400,
    );
    expect(ids, contains('nested-comp'));
  });
}
