import '../../bridge/project_snapshot.dart';

const fxDeviceTypes = <String>{
  'gate',
  'compressor',
  'expander',
  'limiter',
  'bitcrusher',
  'distortion',
  'tremolo',
};

const frequencyFxDeviceTypes = <String>{
  'filter',
  'four_band_eq',
  'frequency_shifter',
  'resonator_bank',
  'audio_receiver',
  'midi_receiver',
  'midi_delay',
};

extension DeviceStripDeviceKind on DeviceSnapshot {
  bool get isFxDevice =>
      fxDeviceTypes.contains(type) || frequencyFxDeviceTypes.contains(type);

  bool get isFrequencyFxDevice => frequencyFxDeviceTypes.contains(type);

  bool get isInstrumentDevice => type != 'track_gain' && !isFxDevice;
}

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
