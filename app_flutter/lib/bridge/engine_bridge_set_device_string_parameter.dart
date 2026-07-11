part of 'engine_bridge.dart';

extension EngineBridgeSetdevicestringparameterOperation on EngineBridge {
Future<void> setDeviceStringParameter({
    required String deviceId,
    required String parameterId,
    required String value,
  }) async {
    return _invokeOk('setDeviceStringParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
      'value': value,
    });
  }
}
