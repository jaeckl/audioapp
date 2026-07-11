part of 'engine_bridge.dart';

extension EngineBridgeAdddevicetodrumpadOperation on EngineBridge {
  Future<ProjectSnapshot> addDeviceToDrumPad({
    required String drumMachineId,
    required int note,
    required String deviceType,
    int? insertIndex,
    String? padName,
  }) =>
      _invokeForSnapshot('addDeviceToDrumPad', {
        'drumMachineId': drumMachineId,
        'note': note,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
        if (padName != null && padName.isNotEmpty) 'padName': padName,
      });
}
