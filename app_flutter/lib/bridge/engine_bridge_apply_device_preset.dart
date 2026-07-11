part of 'engine_bridge.dart';

extension EngineBridgeApplydevicepresetOperation on EngineBridge {
  Future<ProjectSnapshot> applyDevicePreset({
    required String deviceId,
    required String presetJson,
  }) =>
      _invokeForSnapshot('applyDevicePreset', {
        'deviceId': deviceId,
        'presetJson': presetJson,
      });
}
