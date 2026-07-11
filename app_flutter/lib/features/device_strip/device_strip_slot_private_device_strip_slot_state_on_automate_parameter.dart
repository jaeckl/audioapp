part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnautomateparameterOperation
    on _DeviceStripSlotState {
  void _onAutomateParameter(String paramId) {
    widget.onAutomateParameter?.call(widget.device.id, paramId);
  }
}
