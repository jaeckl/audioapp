part of 'engine_bridge.dart';

extension EngineBridgeClearcaptureOperation on EngineBridge {
  Future<void> clearCapture() async {
    await _invokeOk('clearCapture');
  }
}
