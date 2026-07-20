import '../../bridge/project_snapshot.dart';

part 'device_strip_device_kind_track_device_strip_kind.dart';
part 'device_strip_device_kind_track_freeze_device_strip.dart';
const fxDeviceTypes = <String>{
  'gate',
  'compressor',
  'expander',
  'limiter',
  'ducker',
  'utility',
  'bitcrusher',
  'distortion',
  'tremolo',
  'stutter_fx',
  'device_chain',
  'lr_split',
  'ms_split',
};

const frequencyFxDeviceTypes = <String>{
  'filter',
  'four_band_eq',
  'frequency_shifter',
  'resonator_bank',
  'audio_receiver',
  'midi_receiver',
  'midi_delay',
  'oscilloscope',
  'spectrum_analyzer',
  'loudness_meter',
  'stereo_imager',
  'mb_split_2',
  'mb_split_3',
  'mb_split_4',
  'spectral_loud_split',
};

extension DeviceStripDeviceKind on DeviceSnapshot {
  bool get isFxDevice =>
      fxDeviceTypes.contains(type) || frequencyFxDeviceTypes.contains(type);

  bool get isFrequencyFxDevice => frequencyFxDeviceTypes.contains(type);

  bool get isInstrumentDevice => type != 'track_gain' && !isFxDevice;
}

/// Freeze-aware helpers for the device strip (pre-gain chain is baked when frozen).
