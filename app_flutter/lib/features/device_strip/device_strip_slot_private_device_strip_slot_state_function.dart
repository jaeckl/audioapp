part of 'device_strip_slot.dart';

extension DeviceStripSlotStateFunctionOperation on _DeviceStripSlotState {
  void Function(String paramId, double amount)? get _onModulationForDevice {
    final lfoId = _connectModeLfo;
    if (lfoId == null) return null;
    return (String paramId, double amount) {
      _onBridgeCall('assignModulation', {
        'lfoId': lfoId,
        'deviceId': widget.device.id,
        'paramId': paramId,
        'amount': (amount * 100).roundToDouble() / 100,
      });
    };
  }
}
