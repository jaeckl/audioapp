import 'subtractive_synth_presets.dart';

part 'device_preset_store_device_preset.dart';
part 'device_preset_store_drums_kick.dart';
part 'device_preset_store_drums_snare.dart';
part 'device_preset_store_drums_clap.dart';
part 'device_preset_store_drums_hihat.dart';
part 'device_preset_store_drums_rimshot.dart';
part 'device_preset_store_drums_tom.dart';
part 'device_preset_store_drums_ride.dart';
part 'device_preset_store_drums_crash.dart';

/// Generic factory preset payload. The parameter map shape (id -> float) is
/// the same regardless of device type — the engine's `DeviceRegistry`
/// already knows how to apply these params for any registered device.
/// Look up factory presets by (deviceType, presetId).
///
/// Previously the DAW only supported subtractive synth presets
/// (via [SubtractiveSynthPresets]), so selecting a sampler/oscillator
/// preset in the library silently bailed out with no audio. This store
/// unifies all presets behind one lookup.
abstract final class DevicePresetStore {
  static const Map<String, DevicePreset> _granular = {
    'preset:grain-glass-choir': DevicePreset(params: {
      'position': .28,
      'scan': .64,
      'grainSize': .7,
      'density': .55,
      'spray': .16,
      'formant': .62,
      'character': .58,
      'attack': .25,
      'release': .62,
      'spread': .72,
      'formX': .88,
      'formY': .75,
    }, stringParams: {
      'sampleId': 'demo_form_lost_choir'
    }),
    'preset:grain-liquid-air': DevicePreset(params: {
      'position': .42,
      'scan': .58,
      'grainSize': .48,
      'density': .42,
      'spray': .3,
      'formant': .7,
      'character': .35,
      'attack': .38,
      'release': .78,
      'spread': .9,
      'formX': .5,
      'formY': .95,
    }, stringParams: {
      'sampleId': 'demo_form_liquid_air'
    }),
    'preset:grain-talking-bass': DevicePreset(params: {
      'position': .18,
      'scan': .72,
      'grainSize': .24,
      'density': .7,
      'spray': .08,
      'grainPitch': .25,
      'formant': .38,
      'character': .82,
      'attack': .01,
      'release': .28,
      'spread': .24,
      'formX': .12,
      'formY': .25,
    }, stringParams: {
      'sampleId': 'demo_form_vowel_sustain'
    }),
    'preset:grain-metal-bloom': DevicePreset(params: {
      'position': .5,
      'scan': .32,
      'grainSize': .8,
      'density': .33,
      'spray': .52,
      'formant': .76,
      'character': .72,
      'attack': .32,
      'release': .82,
      'spread': 1,
      'formX': .88,
      'formY': .25,
    }, stringParams: {
      'sampleId': 'demo_form_metal_hollow'
    }),
    'preset:grain-vox-motion': DevicePreset(params: {
      'position': .12,
      'scan': .83,
      'grainSize': .36,
      'density': .66,
      'spray': .2,
      'formant': .55,
      'character': .68,
      'attack': .08,
      'release': .5,
      'spread': .64,
      'formX': .12,
      'formY': .75,
    }, stringParams: {
      'sampleId': 'demo_form_vox_riders'
    }),
    'preset:grain-sine-freeze': DevicePreset(params: {
      'position': .67,
      'scan': .5,
      'grainSize': .92,
      'density': .28,
      'spray': .04,
      'formant': .48,
      'character': .2,
      'attack': .52,
      'release': .88,
      'spread': .8,
      'formX': .5,
      'formY': .05,
    }, stringParams: {
      'sampleId': 'demo_form_evolving_sines'
    }),
  };
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
      result[id] =
          DevicePreset(params: Map<String, double>.from(preset.params));
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
      case 'granular_formant_synth':
        return _granular[presetId];
      case 'kick_generator':
        return _kick[presetId];
      case 'snare_generator':
        return _snare[presetId];
      case 'clap_generator':
        return _clap[presetId];
      case 'hihat_generator':
        return _hihat[presetId];
      case 'rimshot_generator':
        return _rimshot[presetId];
      case 'tom_generator':
        return _tom[presetId];
      case 'ride_generator':
        return _ride[presetId];
      case 'crash_generator':
        return _crash[presetId];
      default:
        return null;
    }
  }
}
