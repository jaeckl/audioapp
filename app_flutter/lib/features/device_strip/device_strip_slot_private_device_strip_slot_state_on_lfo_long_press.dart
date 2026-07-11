part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnlfolongpressOperation on _DeviceStripSlotState {
  void _onLfoLongPress(int lfoId) {
    _selectedLfoId = lfoId;
    deviceModulationConnectMode.value =
        deviceModulationConnectMode.value == lfoId ? null : lfoId;
  }
}
