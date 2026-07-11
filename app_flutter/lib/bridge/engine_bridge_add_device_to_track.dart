part of 'engine_bridge.dart';

extension EngineBridgeAdddevicetotrackOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToTrack({
    required String trackId,
    required String deviceType,
    int? insertIndex,
  }) async {
    return _invokeForSnapshot('addDeviceToTrack', {
      'trackId': trackId,
      'deviceType': deviceType,
      if (insertIndex != null) 'insertIndex': insertIndex,
    });
  }
}
