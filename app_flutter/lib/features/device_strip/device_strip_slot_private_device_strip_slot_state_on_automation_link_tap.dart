part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnautomationlinktapOperation
    on _DeviceStripSlotState {
  Future<void> _onAutomationLinkTap(String paramId) async {
    final handler = widget.onAutomationParamSelected;
    if (handler == null) return;
    await handler(widget.device.id, paramId);
  }
}
