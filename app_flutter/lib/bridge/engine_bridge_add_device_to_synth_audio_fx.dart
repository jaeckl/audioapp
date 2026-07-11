part of 'engine_bridge.dart';

extension EngineBridgeAdddevicetosynthaudiofxOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToSynthAudioFx({
    required String deviceId,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToSynthAudioFx', {
        'deviceId': deviceId,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
