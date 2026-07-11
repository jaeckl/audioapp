part of 'device_strip_slot.dart';

extension DeviceStripSlotStateMeterawarechromepanelOperation
    on _DeviceStripSlotState {
  Widget _meterAwareChromePanel(
    Widget Function(DeviceStripChromeBindings bindings) buildPanel,
  ) {
    final listenable = widget.liveMetersListenable;
    if (listenable == null) {
      return buildPanel(_chromeBindings());
    }
    return ValueListenableBuilder<Map<String, DeviceMeterReading>>(
      valueListenable: listenable,
      builder: (context, meters, _) =>
          buildPanel(_chromeBindings(meters[widget.device.id])),
    );
  }
}
