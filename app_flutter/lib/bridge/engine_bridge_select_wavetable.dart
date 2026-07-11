part of 'engine_bridge.dart';

extension EngineBridgeSelectwavetableOperation on EngineBridge {
Future<void> selectWavetable(String deviceId, String wavetableName) async {
    await _invokeOk('setDeviceStringParameter', {
      'deviceId': deviceId,
      'parameterId': 'wavetable',
      'value': wavetableName,
    });
  }
}
