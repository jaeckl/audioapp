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

  /// GM hint pitch for the first monophonic drum generator on this track
  /// (scroll / highlight / live-pad base). Null when a drum_machine is present
  /// so kit lanes are not conflated with a mono-drum anchor.
  ///
  /// Does **not** lock piano-roll draw/persist — MIDI stays chromatic; Key Track
  /// on the device decides whether playback follows note pitch.
  int? get drumAnchorPitch {
    for (final device in visibleDevices) {
      if (device.type == 'drum_machine') return null;
    }
    for (final device in visibleDevices) {
      final anchor = switch (device.type) {
        'kick_generator' => 36,
        'snare_generator' => 38,
        'clap_generator' => 39,
        'hihat_generator' => 42,
        'ride_generator' => 51,
        'tom_generator' => 45,
        'rimshot_generator' => 37,
        'crash_generator' => 49,
        _ => null,
      };
      if (anchor != null) return anchor;
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
