part of 'engine_bridge.dart';

extension EngineBridgeMovedeviceintrackOperation on EngineBridge {
  Future<ProjectSnapshot> moveDeviceInTrack({
    required String deviceId,
    required int toIndex,
  }) async {
    return _invokeForSnapshot('moveDeviceInTrack', {
      'deviceId': deviceId,
      'toIndex': toIndex,
    });
  }
}
