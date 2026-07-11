part of 'engine_bridge.dart';

extension EngineBridgeEnterplaymodeOperation on EngineBridge {
  Future<void> enterPlayMode() async {
    await _invokeOk('enterPlayMode');
  }
}
