part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuilddrummachinedeviceOperation
    on _DeviceStripSlotState {
  Widget _buildDrumMachineDevice(BuildContext context, double contentHeight) {
    return DrumMachineDevicePanel(
      device: widget.device as DrumMachineDeviceSnapshot,
      selectedNote: widget.drumSelectedNote,
      bankStart: widget.drumBankStart,
      chainExpanded: widget.drumChainExpanded,
      onSelectNote: widget.onDrumPadSelected ?? (_) {},
      onBankChanged: widget.onDrumBankChanged ?? (_) {},
      onToggleChain: widget.onDrumChainToggle ?? () {},
      onTriggerNote: widget.onDrumTriggerNote ?? (_) {},
      onEmptyPadTap: widget.onEmptyDrumPadTap ?? (_) {},
    );
  }
}
