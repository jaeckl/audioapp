part 'subtractive_synth_presets_subtractive_preset_mod.dart';
part 'subtractive_synth_presets_subtractive_synth_preset.dart';
part 'subtractive_synth_presets_subtractive_presets_group_1.dart';
part 'subtractive_synth_presets_subtractive_presets_group_2.dart';
part 'subtractive_synth_presets_subtractive_presets_group_3.dart';

part 'subtractive_synth_presets_subtractive_preset_lfo.dart';
/// Factory preset bundles for subtractive_synth devices (params + LFO/mod routing).
abstract final class SubtractiveSynthPresets {
  /// Every exposed subtractive synth knob — presets always replace the full device state.
  static const Map<String, double> initParams = {
    'gain': 1.0,
    'attack': 0.02,
    'decay': 0.25,
    'sustain': 0.75,
    'release': 0.35,
    'filterCutoff': 0.75,
    'filterQ': 0.2,
    'filterMode': 0,
    'filterEnvAmount': 0.5,
    'filterAttack': 0.05,
    'filterDecay': 0.35,
    'filterSustain': 0.4,
    'filterRelease': 0.45,
    'filterKeyTrack': 0.35,
    'filterDrive': 0.0,
    'filterFm': 0.0,
    'filterShaper': 0.0,
    'filterShaperMode': 1,
    'osc1Shape': 0.5,
    'osc2Shape': 0.5,
    'osc1Octave': 0.5,
    'osc2Octave': 0.5,
    'osc1Semi': 0.0,
    'osc2Semi': 0.0,
    'osc1Detune': 0.5,
    'osc2Detune': 0.5,
    'oscMix': 0.37,
    'oscMixMode': 0,
    'osc1Sync': 0.0,
    'osc2Sync': 0.0,
    'noiseLevel': 0.0,
    'unisonVoices': 0.0,
    'unisonDetune': 0.5,
    'glideMs': 0.0,
    'preHpCutoff': 0.0,
    'preHpRes': 0.2,
    'preDrive': 0.0,
    'mixFeedback': 0.0,
    'globalPitch': 0.5,
    'synthMono': 0.0,
    'synthLegato': 0.0,
    'velocitySensitivity': 1.0,
  };

  static const _quarterSine =
      SubtractivePresetLfo(waveform: 0, syncDivision: 3);
  static const _halfTri = SubtractivePresetLfo(waveform: 1, syncDivision: 2);
  static const _barSine = SubtractivePresetLfo(waveform: 0, syncDivision: 1);
  static const _eighthSine = SubtractivePresetLfo(waveform: 0, syncDivision: 4);
  static const _slowSaw = SubtractivePresetLfo(waveform: 2, syncDivision: 3);
  static const _sixteenthTri =
      SubtractivePresetLfo(waveform: 1, syncDivision: 5);
  static const _eighthSquare =
      SubtractivePresetLfo(waveform: 3, syncDivision: 4);
  static const _halfSine = SubtractivePresetLfo(waveform: 0, syncDivision: 2);

  static Map<String, double> _patch(Map<String, double> overrides) => {
        ...initParams,
        ...overrides,
      };

  static SubtractiveSynthPreset _bundle(
    Map<String, double> overrides, {
    List<SubtractivePresetLfo> lfos = const [],
    List<SubtractivePresetMod> mods = const [],
  }) =>
      SubtractiveSynthPreset(params: _patch(overrides), lfos: lfos, mods: mods);

  static final Map<String, SubtractiveSynthPreset> presets = {
    ..._subtractive_presetsGroup1,
    ..._subtractive_presetsGroup2,
    ..._subtractive_presetsGroup3,
  };
}
