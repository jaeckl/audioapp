part of 'engine_bridge.dart';

extension EngineBridgeAdddevicetochainOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToChain({
    required String chainId,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToChain', {
        'chainId': chainId,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
