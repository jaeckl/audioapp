part of 'device_strip_device_kind.dart';

extension TrackDeviceStripKind on TrackSnapshot {
  int get visibleInstrumentCount =>
      visibleDevices.where((device) => device.isInstrumentDevice).length;

  bool hasLinkedAutomationFor(String deviceId) {
    for (final clip in automationClips) {
      if (clip.deviceId == deviceId && clip.isLinked) {
        return true;
      }
    }
    return false;
  }
}
