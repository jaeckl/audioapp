part of 'engine_bridge.dart';

extension EngineBridgeRemovedevicefromtrackOperation on EngineBridge {
Future<ProjectSnapshot> removeDeviceFromTrack({
    required String deviceId,
  }) async {
    return _invokeForSnapshot('removeDeviceFromTrack', {
      'deviceId': deviceId,
    });
  }
}
