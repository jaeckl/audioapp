part of 'engine_bridge.dart';

extension EngineBridgeRemoveDeviceFromSpectralLoudPreFxOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromSpectralLoudPreFx({
    required String deviceId,
    required String childId,
  }) =>
      _invokeForSnapshot('removeDeviceFromSpectralLoudPreFx', {
        'deviceId': deviceId,
        'childId': childId,
      });
}
