part of 'engine_bridge.dart';

extension EngineBridgeStoppreviewOperation on EngineBridge {
Future<void> stopPreview() async {
    await _invokeOk('stopPreview');
  }
}
