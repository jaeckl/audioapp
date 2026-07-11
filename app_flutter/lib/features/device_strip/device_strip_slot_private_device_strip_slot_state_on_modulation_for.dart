part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnmodulationforOperation
    on _DeviceStripSlotState {
  ValueChanged<double> _onModulationFor(String paramId) {
    final lfoId = _connectModeLfo;
    if (lfoId == null) return (_) {};
    return (double amount) {
      _onBridgeCall('assignModulation', {
        'lfoId': lfoId,
        'deviceId': widget.device.id,
        'paramId': paramId,
        'amount': (amount * 100).roundToDouble() / 100,
      });
    };
  }
}
