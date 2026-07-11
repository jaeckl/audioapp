part of 'engine_bridge.dart';

extension EngineBridgeSetdeviceparameterOperation on EngineBridge {
Future<void> setDeviceParameter({
    required String deviceId,
    required String parameterId,
    required double value,
  }) async {
    return _invokeOk('setDeviceParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
      'value': value,
    });
  }
}
