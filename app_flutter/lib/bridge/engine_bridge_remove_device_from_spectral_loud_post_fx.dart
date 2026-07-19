part of 'engine_bridge.dart';

extension EngineBridgeRemoveDeviceFromSpectralLoudPostFxOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromSpectralLoudPostFx({
    required String deviceId,
    required String childId,
  }) =>
      _invokeForSnapshot('removeDeviceFromSpectralLoudPostFx', {
        'deviceId': deviceId,
        'childId': childId,
      });
}
