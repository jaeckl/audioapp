part of 'device_strip_slot.dart';

extension DeviceStripSlotStateSyncglobalconnectmodeOperation
    on _DeviceStripSlotState {
  void _syncGlobalConnectMode() {
    if (!mounted) return;
    setState(() => _connectModeLfoId = deviceModulationConnectMode.value);
  }
}
