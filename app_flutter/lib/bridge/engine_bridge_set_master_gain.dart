part of 'engine_bridge.dart';

extension EngineBridgeSetmastergainOperation on EngineBridge {
Future<void> setMasterGain(double gain) async {
    return _invokeOk('setMasterGain', {'gain': gain});
  }
}
