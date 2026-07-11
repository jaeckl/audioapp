part of 'engine_bridge.dart';

extension EngineBridgePingOperation on EngineBridge {
  Future<String> ping() async {
    final result = await _channel.invokeMethod<String>('ping');
    return result ?? '';
  }
}
