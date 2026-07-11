part of 'engine_bridge.dart';

extension EngineBridgeRemovedevicefromsynthaudiofxOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromSynthAudioFx({
    required String deviceId,
    required String subDeviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromSynthAudioFx', {
        'deviceId': deviceId,
        'subDeviceId': subDeviceId,
      });
}
