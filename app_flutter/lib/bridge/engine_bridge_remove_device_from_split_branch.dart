part of 'engine_bridge.dart';

extension EngineBridgeRemoveDeviceFromSplitBranchOperation on EngineBridge {
  Future<ProjectSnapshot> removeDeviceFromSplitBranch({
    required String splitId,
    required int branchIndex,
    required String deviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromSplitBranch', {
        'splitId': splitId,
        'branchIndex': branchIndex,
        'deviceId': deviceId,
      });
}
