part of 'engine_bridge.dart';

extension EngineBridgeRemoveDeviceFromSpectralLoudBandOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromSpectralLoudBand({
    required String deviceId,
    required int bandIndex,
    required String childId,
  }) =>
      _invokeForSnapshot('removeDeviceFromSpectralLoudBand', {
        'deviceId': deviceId,
        'bandIndex': bandIndex,
        'childId': childId,
      });
}
