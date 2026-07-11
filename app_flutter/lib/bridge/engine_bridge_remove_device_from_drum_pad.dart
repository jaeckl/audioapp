part of 'engine_bridge.dart';

extension EngineBridgeRemovedevicefromdrumpadOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromDrumPad({
    required String drumMachineId,
    required int note,
    required String deviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromDrumPad', {
        'drumMachineId': drumMachineId,
        'note': note,
        'deviceId': deviceId,
      });
}
