import 'package:audioapp/bridge/engine_bridge.dart';
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
      }
      return {'ok': false, 'error': 'unexpected'};
    });
  });

  tearDown(() {
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
}
