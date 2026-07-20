part 'bass_synth_presets_types.dart';
part 'bass_synth_presets_fx.dart';
part 'bass_synth_presets_group_1.dart';
part 'bass_synth_presets_group_2.dart';
part 'bass_synth_presets_group_3.dart';

/// Factory presets for `bass_synth` — full applyDevicePreset documents
/// (params + optional LFO/mod + nested audio FX strip).
abstract final class BassSynthPresets {
  static const Map<String, double> initParams = {
    'bassOscShape': 0.3,
    'bassSubMix': 0.5,
    'bassSubOctave': 0.0,
    'bassNoise': 0.0,
    'bassFilterResonance': 0.25,
    'bassDrive': 0.0,
    'bassSquash': 0.0,
    'bassOctave': 2.0,
    'bassVelocitySense': 1.0,
    'filterCutoff': 0.85,
    'attack': 0.02,
    'sustain': 0.8,
    'release': 0.35,
    'filterEnvAmount': 0.55,
    'filterDecay': 0.4,
    'glideMs': 0.0,
  };

  static const _quarterSine = BassPresetLfo(waveform: 0, syncDivision: 3);
  static const _eighthSine = BassPresetLfo(waveform: 0, syncDivision: 4);
  static const _sixteenthTri = BassPresetLfo(waveform: 1, syncDivision: 5);
  static const _halfTri = BassPresetLfo(waveform: 1, syncDivision: 2);
  static const _barSine = BassPresetLfo(waveform: 0, syncDivision: 1);
  static const _eighthSquare = BassPresetLfo(waveform: 3, syncDivision: 4);
  static const _slowSaw = BassPresetLfo(waveform: 2, syncDivision: 2);

  static Map<String, double> _patch(Map<String, double> overrides) => {
        ...initParams,
        ...overrides,
      };

  static BassSynthPreset _bundle(
    Map<String, double> overrides, {
    List<BassPresetLfo> lfos = const [],
    List<BassPresetMod> mods = const [],
    List<Map<String, dynamic>> audioFx = const [],
  }) =>
      BassSynthPreset(
        params: _patch(overrides),
        lfos: lfos,
        mods: mods,
        audioFx: audioFx,
      );

  static final Map<String, BassSynthPreset> presets = {
    ..._bassPresetsGroup1,
    ..._bassPresetsGroup2,
    ..._bassPresetsGroup3,
  };

  /// Full `applyDevicePreset` document, or null if unknown.
  static Map<String, dynamic>? documentFor(String presetId) {
    final preset = presets[presetId];
    if (preset == null) return null;

    final modulators = <Map<String, dynamic>>[];
    for (var i = 0; i < preset.lfos.length; i++) {
      modulators.add(preset.lfos[i].toJson(i + 1));
    }
    final modEdges = <Map<String, dynamic>>[
      for (final m in preset.mods)
        {
          'lfoId': m.lfoIndex + 1,
          'deviceId': 'factory',
          'paramId': m.paramId,
          'amount': m.amount,
        },
    ];

    return {
      'presetVersion': 2,
      'device': {
        'id': 'factory',
        'type': 'bass_synth',
        'bypass': false,
        'parameters': {
          for (final e in preset.params.entries) e.key: e.value,
        },
        'outputPanel': {'type': 'stereo', 'gain': 1.0, 'pan': 0.5},
        'inputPanel': {'type': 'empty'},
        'audioFxDevices': preset.audioFx,
        'noteFxDevices': <dynamic>[],
      },
      'automationClips': <dynamic>[],
      'modulators': modulators,
      'modEdges': modEdges,
    };
  }
}
