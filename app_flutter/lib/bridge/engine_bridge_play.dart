part of 'engine_bridge.dart';

extension EngineBridgePlayOperation on EngineBridge {
  Future<void> play() async {
    await _channel.invokeMethod<void>('play');
  }
}
