part of 'bass_synth_presets.dart';

/// Shared FX device builders for nested `audioFxDevices`.
abstract final class _BassFx {
  static Map<String, dynamic> _stereoOut({
    double gain = 1.0,
    double mix = 1.0,
    double width = 1.0,
  }) =>
      {
        'type': 'stereo',
        'gain': gain,
        'pan': 0.5,
        'outputMix': mix,
        'outputWidth': width,
      };

  static Map<String, dynamic> distortion({
    required String id,
    double drive = 0.55,
    double sym = 0.5,
    double tone = 0.45,
    double mix = 0.65,
  }) =>
      {
        'id': id,
        'type': 'distortion',
        'bypass': false,
        'parameters': {
          'drive': drive,
          'sym': sym,
          'tone': tone,
          'mix': mix,
        },
        'outputPanel': _stereoOut(mix: mix),
        'inputPanel': {'type': 'empty'},
      };

  static Map<String, dynamic> filter({
    required String id,
    double cutoff = 0.45,
    double resonance = 0.35,
    double mode = 0.0,
  }) =>
      {
        'id': id,
        'type': 'filter',
        'bypass': false,
        'parameters': {
          'ffxCutoff': cutoff,
          'ffxResonance': resonance,
          'ffxFilterMode': mode,
        },
        'outputPanel': _stereoOut(),
        'inputPanel': {'type': 'empty'},
      };

  static Map<String, dynamic> chorus({
    required String id,
    double mix = 0.35,
  }) =>
      {
        'id': id,
        'type': 'chorus',
        'bypass': false,
        'parameters': {
          'modeMorph': 0.0,
          'rateHz': 1.2,
          'depth': 0.35,
          'centreDelayMs': 8.0,
          'feedback': 0.1,
        },
        'outputPanel': _stereoOut(mix: mix, width: 1.1),
        'inputPanel': {'type': 'empty'},
      };

  static Map<String, dynamic> phaser({
    required String id,
    double mix = 0.4,
  }) =>
      {
        'id': id,
        'type': 'phaser',
        'bypass': false,
        'parameters': {
          'depth': 0.55,
          'rateHz': 0.35,
          'feedback': 0.35,
          'centreFrequencyHz': 600.0,
          'stages': 6.0,
        },
        'outputPanel': _stereoOut(mix: mix),
        'inputPanel': {'type': 'empty'},
      };

  static Map<String, dynamic> bitcrusher({
    required String id,
    double rate = 0.35,
    double bits = 6.0,
    double mix = 0.45,
  }) =>
      {
        'id': id,
        'type': 'bitcrusher',
        'bypass': false,
        'parameters': {
          'rate': rate,
          'bits': bits,
          'mode': 0.0,
          'shape': 0.2,
          'jitter': 0.05,
          'drive': 0.15,
          'filter': 0.4,
          'mix': mix,
        },
        'outputPanel': _stereoOut(mix: mix),
        'inputPanel': {'type': 'empty'},
      };

  static Map<String, dynamic> compressor({
    required String id,
    double threshold = 0.45,
    double ratio = 0.65,
    double makeup = 0.4,
  }) =>
      {
        'id': id,
        'type': 'compressor',
        'bypass': false,
        'parameters': {
          'inputGain': 1.0,
          'compThreshold': threshold,
          'compRatio': ratio,
          'compAttack': 0.15,
          'compRelease': 0.5,
          'compKnee': 0.3,
          'compMakeup': makeup,
        },
        'outputPanel': _stereoOut(),
        // Compressor requires DynamicsInputPanel — empty aborts native apply.
        'inputPanel': {'type': 'dynamics', 'trim': 1.0},
      };

  static Map<String, dynamic> delay({
    required String id,
    double timeMs = 380.0,
    double feedback = 0.28,
    double mix = 0.22,
  }) =>
      {
        'id': id,
        'type': 'delay',
        'bypass': false,
        'parameters': {
          'timeMs': timeMs,
          'feedback': feedback,
          'timeMode': 0.0,
          'lowCutHz': 80.0,
          'highCutHz': 6000.0,
          'mix': mix,
        },
        'outputPanel': _stereoOut(mix: mix),
        'inputPanel': {'type': 'empty'},
      };

  static Map<String, dynamic> ringMod({
    required String id,
    double shift = 0.58,
    double mix = 0.35,
    double tone = 0.7,
  }) =>
      {
        'id': id,
        'type': 'frequency_shifter',
        'bypass': false,
        'parameters': {
          'ffxShift': shift,
          'ffxFine': 0.5,
          'ffxMix': mix,
          'ffxTone': tone,
          'ffxFeedback': 0.1,
        },
        'outputPanel': _stereoOut(),
        'inputPanel': {'type': 'empty'},
      };
}
