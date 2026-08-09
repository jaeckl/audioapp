part of 'device_strip_device_kind.dart';

extension TrackFreezeDeviceStrip on TrackSnapshot {
  int get trackGainDeviceIndex =>
      devices.indexWhere((device) => device.type == 'track_gain');

  bool get canInsertDevices => !freeze.isManual;

  bool isPreGainDeviceDimmed(DeviceSnapshot device) {
    if (!freeze.isManual || device.type == 'track_gain') {
      return false;
    }
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
}
