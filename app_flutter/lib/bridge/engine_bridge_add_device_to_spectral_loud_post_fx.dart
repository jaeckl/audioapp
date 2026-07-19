part of 'engine_bridge.dart';

extension EngineBridgeAddDeviceToSpectralLoudPostFxOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToSpectralLoudPostFx({
    required String deviceId,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToSpectralLoudPostFx', {
        'deviceId': deviceId,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
