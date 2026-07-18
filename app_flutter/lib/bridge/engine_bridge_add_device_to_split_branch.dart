part of 'engine_bridge.dart';

extension EngineBridgeAddDeviceToSplitBranchOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToSplitBranch({
    required String splitId,
    required int branchIndex,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToSplitBranch', {
        'splitId': splitId,
        'branchIndex': branchIndex,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });
}
