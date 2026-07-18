import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:audioapp/features/device_strip/effective_parameter_monitor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine.graph-tap-test');
  final bridge = EngineBridge(channel: channel);
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'createGraphTap':
          return {'ok': true, 'tapId': 'tap-7'};
        case 'removeGraphTap':
          return {'ok': true};
        case 'readGraphTap':
          return {
            'ok': true,
            'tapId': 'tap-7',
            'type': 'meter',
            'sequence': 3,
            'peakL': 0.5,
          };
        case 'readEffectiveParameter':
          return {
            'ok': true,
            'value': 0.625,
            'automationBase': 0.375,
          };
        case 'readEffectiveParameters':
          return {
            'ok': true,
            'values': [
              {'value': 0.625, 'automationBase': 0.375},
            ],
          };
      }
      return {'ok': false, 'error': 'unexpected'};
    });
  });

  tearDown(() {
    effectiveParameterMonitor.stop();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('graph tap lifecycle uses bounded raw bridge commands', () async {
    final tapId = await bridge.createGraphTap(
      deviceId: 'dev-1',
      kind: 'recorder',
      capacityFrames: 4096,
    );
    expect(tapId, 'tap-7');
    expect(calls.first.arguments, {
      'deviceId': 'dev-1',
      'kind': 'recorder',
      'capacityFrames': 4096,
    });

    final reading = await bridge.readGraphTap(tapId, maxFrames: 128);
    expect(reading['sequence'], 3);
    expect(calls[1].arguments, {'tapId': 'tap-7', 'maxFrames': 128});

    await bridge.removeGraphTap(tapId);
    expect(calls.last.method, 'removeGraphTap');
    expect(calls.last.arguments, {'tapId': 'tap-7'});
  });

  test('graph tap forwards an explicit logical port', () async {
    await bridge.createGraphTap(
      deviceId: 'dev-1',
      kind: 'meter',
      port: 'processor',
    );
    expect(calls.single.arguments, {
      'deviceId': 'dev-1',
      'kind': 'meter',
      'capacityFrames': 32768,
      'port': 'processor',
    });
  });

  test('effective parameter monitor uses a compact coalescible read', () async {
    final value = await bridge.readEffectiveParameter(
      deviceId: 'dev-2',
      parameterId: 'drive',
    );
    expect(value, 0.625);
    expect(calls.single.method, 'readEffectiveParameter');
    expect(calls.single.arguments, {
      'deviceId': 'dev-2',
      'parameterId': 'drive',
    });
  });

  testWidgets('visible effective controls are polled on one coalesced timer',
      (tester) async {
    const key = (deviceId: 'dev-2', parameterId: 'drive');
    effectiveParameterMonitor.start(bridge);
    effectiveParameterMonitor.register(key);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump();

    expect(effectiveParameterMonitor.valueFor(key), 0.375);
    expect(effectiveParameterMonitor.effectiveValueFor(key), 0.625);
    expect(calls.where((call) => call.method == 'readEffectiveParameters'),
        hasLength(1));
    expect(calls.single.arguments, {
      'requests': [
        {'deviceId': 'dev-2', 'parameterId': 'drive'},
      ],
    });
    effectiveParameterMonitor.unregister(key);
    effectiveParameterMonitor.stop();
  });
}
