part 'phase_mod_synth_presets_phase_mod_presets_group_1.dart';
part 'phase_mod_synth_presets_phase_mod_presets_group_2.dart';
part 'phase_mod_synth_presets_phase_mod_presets_group_3.dart';
part 'phase_mod_synth_presets_phase_mod_presets_group_4.dart';
part 'phase_mod_synth_presets_phase_mod_presets_group_5.dart';

/// Factory preset bundles for phase_mod_synth devices.
///
/// Each preset is a map of parameter_id → value (full patch over defaults).
abstract final class PhaseModSynthPresets {
  static Map<String, dynamic> _patch(Map<String, dynamic> overrides) {
    return {..._defaults, ...overrides};
  }

  /// Full `applyDevicePreset` document, or null if unknown.
  static Map<String, dynamic>? documentFor(String presetId) {
    final params = presets[presetId];
    if (params == null) return null;
    return {
      'presetVersion': 2,
      'device': {
        'id': 'factory',
        'type': 'phase_mod_synth',
        'bypass': false,
        'parameters': Map<String, dynamic>.from(params),
        'outputPanel': {'type': 'stereo', 'gain': 1.0, 'pan': 0.5},
        'inputPanel': {'type': 'empty'},
        'audioFxDevices': <dynamic>[],
        'noteFxDevices': <dynamic>[],
      },
      'automationClips': <dynamic>[],
      'modulators': <dynamic>[],
      'modEdges': <dynamic>[],
    };
  }

  static const Map<String, dynamic> _defaults = {
    // Operator 1
    'pmOp1Ratio': 0.0625,
    'pmOp1Fine': 0.5,
    'pmOp1Level': 0.8,
    'pmOp1Wave': 0.0,
    'pmOp1Attack': 0.01,
    'pmOp1Decay': 0.3,
    'pmOp1Sustain': 0.8,
    'pmOp1Release': 0.4,
    'pmOp1VelSense': 1.0,
    'pmOp1KeyTrack': 0.0,
    // Operator 2
    'pmOp2Ratio': 0.4375,
    'pmOp2Fine': 0.5,
    'pmOp2Level': 0.4,
    'pmOp2Wave': 0.0,
    'pmOp2Attack': 0.01,
    'pmOp2Decay': 0.3,
    'pmOp2Sustain': 0.8,
    'pmOp2Release': 0.4,
    'pmOp2VelSense': 1.0,
    'pmOp2KeyTrack': 0.0,
    // Operator 3
    'pmOp3Ratio': 0.75,
    'pmOp3Fine': 0.5,
    'pmOp3Level': 0.0,
    'pmOp3Wave': 0.0,
    'pmOp3Attack': 0.01,
    'pmOp3Decay': 0.3,
    'pmOp3Sustain': 0.8,
    'pmOp3Release': 0.4,
    'pmOp3VelSense': 1.0,
    'pmOp3KeyTrack': 0.0,
    // Operator 4
    'pmOp4Ratio': 0.375,
    'pmOp4Fine': 0.5,
    'pmOp4Level': 0.0,
    'pmOp4Wave': 0.0,
    'pmOp4Attack': 0.01,
    'pmOp4Decay': 0.3,
    'pmOp4Sustain': 0.8,
    'pmOp4Release': 0.4,
    'pmOp4VelSense': 1.0,
    'pmOp4KeyTrack': 0.0,
    // Global
    'pmAlgoIndex': 0,
    'pmFeedback': 0.0,
    'pmUnisonVoices': 0.0,
    'pmUnisonDetune': 0.15,
    'pmGlide': 0.0,
    'pmMono': 0.0,
    'pmLegato': 0.0,
    'pmMasterVol': 0.85,
    // LFO
    'pmLfoRate': 0.2,
    'pmLfoShape': 0.0,
    'pmLfoAmount': 0.0,
    'pmLfoDest': 0,
    'pmVibratoDepth': 0.0,
    'pmVibratoRate': 0.3,
    // Shared filter/amp fields (match DeviceSnapshot defaults for phase_mod_synth)
    'gain': 1.0,
    'attack': 0.01,
    'decay': 0.3,
    'sustain': 0.75,
    'release': 0.35,
    'filterCutoff': 0.85,
    'filterQ': 0.25,
    'filterMode': 0,
    'filterEnvAmount': 0.5,
    'filterAttack': 0.05,
    'filterDecay': 0.35,
    'filterSustain': 0.4,
    'filterRelease': 0.45,
    'filterKeyTrack': 0.0,
  };

  static final Map<String, Map<String, dynamic>> presets = {
    ..._phase_mod_presetsGroup1,
    ..._phase_mod_presetsGroup2,
    ..._phase_mod_presetsGroup3,
    ..._phase_mod_presetsGroup4,
    ..._phase_mod_presetsGroup5,
  };
}
