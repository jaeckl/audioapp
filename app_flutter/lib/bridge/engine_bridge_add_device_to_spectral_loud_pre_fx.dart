part of 'engine_bridge.dart';

extension EngineBridgeAddDeviceToSpectralLoudPreFxOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToSpectralLoudPreFx({
    required String deviceId,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToSpectralLoudPreFx', {
        'deviceId': deviceId,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
