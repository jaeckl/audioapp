part of 'daw_shell.dart';

extension DawShellStateTrackowningdeviceOperation on _DawShellState {
TrackSnapshot? _trackOwningDevice(String deviceId) {
    final snapshot = _snapshot;
    if (snapshot == null) return null;
    bool containsDevice(Iterable<DeviceSnapshot> devices) {
      for (final device in devices) {
        if (device.id == deviceId) return true;
        if (device is ChainDeviceSnapshot && containsDevice(device.devices)) {
          return true;
        }
        if (device is SplitDeviceSnapshot &&
            (containsDevice(device.branch0) ||
                containsDevice(device.branch1))) {
          return true;
        }
        if (device is DrumMachineDeviceSnapshot) {
          for (final pad in device.pads) {
            if (containsDevice(pad.devices)) return true;
          }
        }
        if (containsDevice(device.audioFxDevices)) return true;
        if (containsDevice(device.noteFxDevices)) return true;
      }
      return false;
    }

    for (final track in snapshot.tracks) {
      if (containsDevice(track.devices)) return track;
    }
    return null;
  }
}
