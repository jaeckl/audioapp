part of 'engine_bridge.dart';

extension EngineBridgeAddDeviceToSpectralLoudBandOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToSpectralLoudBand({
    required String deviceId,
    required int bandIndex,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToSpectralLoudBand', {
        'deviceId': deviceId,
        'bandIndex': bandIndex,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
