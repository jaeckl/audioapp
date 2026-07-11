part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildoscilloscopedeviceOperation
    on _DeviceStripSlotState {
  Widget _buildOscilloscopeDevice(BuildContext context, double contentHeight) {
    Widget panel(DeviceMeterReading? reading) => DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child:
              AnalysisDevicePanel(type: widget.device.type, reading: reading),
        );
    final listenable = widget.liveMetersListenable;
    if (listenable == null) return panel(null);
    return ValueListenableBuilder<Map<String, DeviceMeterReading>>(
      valueListenable: listenable,
      builder: (_, meters, __) => panel(meters[widget.device.id]),
    );
  }
}
