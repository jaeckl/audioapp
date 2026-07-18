part of 'engine_bridge.dart';

extension EngineBridgeAddDeviceToMultibandBandOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToMultibandBand({
    required String mbId,
    required int bandIndex,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToMultibandBand', {
        'mbId': mbId,
        'bandIndex': bandIndex,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
