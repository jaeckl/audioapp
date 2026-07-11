part of 'engine_bridge.dart';

extension EngineBridgeRemovedevicefromsynthnotefxOperation on EngineBridge {
Future<ProjectSnapshot> removeDeviceFromSynthNoteFx({
    required String deviceId,
    required String subDeviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromSynthNoteFx', {
        'deviceId': deviceId,
        'subDeviceId': subDeviceId,
      });
}
