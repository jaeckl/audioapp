part of 'engine_bridge.dart';

extension EngineBridgeRemoveDeviceFromMultibandBandOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromMultibandBand({
    required String mbId,
    required int bandIndex,
    required String deviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromMultibandBand', {
        'mbId': mbId,
        'bandIndex': bandIndex,
        'deviceId': deviceId,
      });
}
