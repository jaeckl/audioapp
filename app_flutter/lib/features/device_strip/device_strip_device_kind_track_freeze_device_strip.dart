part of 'device_strip_device_kind.dart';

extension TrackFreezeDeviceStrip on TrackSnapshot {
  int get trackGainDeviceIndex =>
      devices.indexWhere((device) => device.type == 'track_gain');

  bool get canInsertDevices => !freeze.isManual;

  /// Matches engine `flattenedPlaybackSlotCount` for synth hosts.
  int _flattenedPlaybackSlotCount(DeviceSnapshot device) {
    if (!DeviceCapabilities.virtualStripHosts.contains(device.type)) {
      return 1;
    }
    return 1 + device.noteFxDevices.length + device.audioFxDevices.length;
  }

  bool _deviceTreeContains(DeviceSnapshot root, String deviceId) {
    if (root.id == deviceId) {
      return true;
    }
    for (final child in root.noteFxDevices) {
      if (_deviceTreeContains(child, deviceId)) {
        return true;
      }
    }
    for (final child in root.audioFxDevices) {
      if (_deviceTreeContains(child, deviceId)) {
        return true;
      }
    }
    return false;
  }

  /// Dim devices covered by the freeze bake (flattened bakeEnd), not every
  /// model-space slot before `track_gain`.
  bool isPreGainDeviceDimmed(DeviceSnapshot device) {
    if (!freeze.isManual || device.type == 'track_gain') {
      return false;
    }
    final bakeEnd = freeze.bakeEndDeviceIndex;
    if (bakeEnd <= 0) {
      // Legacy / missing bakeEnd: fall back to model index before gain.
      final gainIndex = trackGainDeviceIndex;
      if (gainIndex < 0) {
        return true;
      }
      final deviceIndex = devices.indexWhere((d) => d.id == device.id);
      if (deviceIndex < 0) {
        return false;
      }
      return deviceIndex < gainIndex;
    }

    var flat = 0;
    for (final root in devices) {
      final slots = _flattenedPlaybackSlotCount(root);
      if (flat + slots > bakeEnd) {
        return false;
      }
      if (_deviceTreeContains(root, device.id)) {
        return true;
      }
      flat += slots;
    }
    return false;
  }
}
