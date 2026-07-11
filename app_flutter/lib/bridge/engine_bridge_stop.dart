part of 'engine_bridge.dart';

extension EngineBridgeStopOperation on EngineBridge {
Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }
}
