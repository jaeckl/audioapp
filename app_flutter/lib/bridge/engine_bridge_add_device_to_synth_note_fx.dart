part of 'engine_bridge.dart';

extension EngineBridgeAdddevicetosynthnotefxOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToSynthNoteFx({
    required String deviceId,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToSynthNoteFx', {
        'deviceId': deviceId,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
