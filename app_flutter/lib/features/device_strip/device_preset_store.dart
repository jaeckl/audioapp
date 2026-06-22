import 'subtractive_synth_presets.dart';

/// Generic factory preset payload. The parameter map shape (id -> float) is
/// the same regardless of device type — the engine's `DeviceRegistry`
/// already knows how to apply these params for any registered device.
class DevicePreset {
  const DevicePreset({required this.params});
  final Map<String, double> params;
}

/// Look up factory presets by (deviceType, presetId).
///
/// Previously the DAW only supported subtractive synth presets
/// (via [SubtractiveSynthPresets]), so selecting a sampler/oscillator
/// preset in the library silently bailed out with no audio. This store
/// unifies all presets behind one lookup.
abstract final class DevicePresetStore {
  static const Map<String, DevicePreset> _sampler = {
    'preset:sampler-warm': DevicePreset(params: {
      'attack': 0.005,
      'decay': 0.18,
      'sustain': 0.4,
      'release': 0.18,
      'filterCutoff': 0.78,
      'filterQ': 0.12,
      'gain': 0.85,
    }),
    'preset:sampler-lofi': DevicePreset(params: {
      'attack': 0.01,
      'decay': 0.3,
      'sustain': 0.5,
      'release': 0.4,
      'filterCutoff': 0.42,
      'filterQ': 0.35,
      'gain': 0.8,
    }),
  };

  static const Map<String, DevicePreset> _oscillator = {
    'preset:osc-pluck': DevicePreset(params: {
      'frequency': 440.0,
      'gain': 0.7,
      'attack': 0.005,
      'release': 0.25,
    }),
    'preset:osc-bass': DevicePreset(params: {
      'frequency': 110.0,
      'gain': 0.9,
      'attack': 0.01,
      'release': 0.4,
    }),
  };

  /// Mirror the legacy [SubtractiveSynthPresets.presets] entries under the
  /// `subtractive_synth` device type id used by the library manifest.
  static Map<String, DevicePreset> get _subtractive {
    final result = <String, DevicePreset>{};
    SubtractiveSynthPresets.presets.forEach((id, preset) {
      result[id] = DevicePreset(params: Map<String, double>.from(preset.params));
    });
    return result;
  }

  /// Look up a preset by device type and id. Returns null when the preset
  /// isn't registered; callers can fall back to default device params.
  static DevicePreset? find(String deviceType, String presetId) {
    switch (deviceType) {
      case 'subtractive_synth':
        return _subtractive[presetId];
      case 'simple_sampler':
        return _sampler[presetId];
      case 'simple_oscillator':
        return _oscillator[presetId];
      default:
        return null;
    }
  }
}