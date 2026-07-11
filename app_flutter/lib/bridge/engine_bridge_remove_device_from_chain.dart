part of 'engine_bridge.dart';

extension EngineBridgeRemovedevicefromchainOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromChain({
    required String chainId,
    required String deviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromChain', {
        'chainId': chainId,
        'deviceId': deviceId,
      });
}
