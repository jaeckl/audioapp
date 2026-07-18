part of 'project_snapshot.dart';

extension TrackSnapshotDevices on TrackSnapshot {
  /// FX/instrument devices shown in the arrangement device strip (excludes track_gain).
  Iterable<DeviceSnapshot> get visibleDevices =>
      devices.where((device) => device.type != 'track_gain');

  SamplerDeviceSnapshot? get samplerDevice {
    for (final device in visibleDevices) {
      if (device is SamplerDeviceSnapshot) {
        return device;
      }
    }
    return null;
  }

  OscillatorDeviceSnapshot? get oscillatorDevice {
    for (final device in visibleDevices) {
      if (device is OscillatorDeviceSnapshot) {
        return device;
      }
    }
    return null;
  }

  SubtractiveSynthDeviceSnapshot? get subtractiveSynthDevice {
    for (final device in visibleDevices) {
      if (device is SubtractiveSynthDeviceSnapshot) {
        return device;
      }
    }
    return null;
  }

  /// GM anchor pitch for monophonic drum generators (snare = 38, etc.).
  int? get drumAnchorPitch {
    for (final device in visibleDevices) {
      switch (device.type) {
        case 'kick_generator':
          return 36;
        case 'snare_generator':
          return 38;
        case 'clap_generator':
          return 39;
        case 'hihat_generator':
          return 42;
        case 'ride_generator':
          return 51;
        case 'tom_generator':
          return 45;
        case 'rimshot_generator':
          return 37;
        case 'crash_generator':
          return 49;
      }
    }
    return null;
  }

  TrackGainDeviceSnapshot? get trackGainDevice {
    for (var i = devices.length - 1; i >= 0; i--) {
      final d = devices[i];
      if (d is TrackGainDeviceSnapshot) {
        return d;
      }
    }
    return null;
  }
}
