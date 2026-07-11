part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnbypassmodulationassignOperation
    on _DeviceStripSlotState {
  void _onBypassModulationAssign(double amount) {
    final lfoId = _connectModeLfo;
    if (lfoId == null) return;
    final existing = _localModEdges.any((edge) =>
        edge.lfoId == lfoId &&
        edge.deviceId == widget.device.id &&
        edge.paramId == 'bypass');
    if (existing) {
      _onBridgeCall('removeModulation', {
        'lfoId': lfoId,
        'deviceId': widget.device.id,
        'paramId': 'bypass',
      });
      return;
    }
    _onBridgeCall('assignModulation', {
      'lfoId': lfoId,
      'deviceId': widget.device.id,
      'paramId': 'bypass',
      'amount': 1.0,
    });
  }
}
