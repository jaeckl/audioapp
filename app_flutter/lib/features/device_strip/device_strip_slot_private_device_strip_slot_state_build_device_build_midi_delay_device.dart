part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildmididelaydeviceOperation
    on _DeviceStripSlotState {
  Widget _buildMidiDelayDevice(BuildContext context, double contentHeight) {
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: MidiDelayPanel(
        device: widget.device as MidiDelayDeviceSnapshot,
        onParameterChanged: widget.onDeviceParameterChanged,
      ),
    );
  }
}
