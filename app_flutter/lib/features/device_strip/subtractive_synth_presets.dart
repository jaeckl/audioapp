/// Factory preset bundles for subtractive_synth devices (params + LFO/mod routing).
class SubtractivePresetLfo {
  const SubtractivePresetLfo({
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 3,
    this.phase = 0.0,
    this.polarity = 0,
  });

  final int waveform;
  final double rate;
  final int syncDivision;
  final double phase;
  final int polarity;

  Map<String, dynamic> toJson() => {
        'waveform': waveform,
        'rate': rate,
        'syncDivision': syncDivision,
        'phase': phase,
        'polarity': polarity,
      };
}

class SubtractivePresetMod {
  const SubtractivePresetMod({
    required this.lfoIndex,
    required this.paramId,
    required this.amount,
  });

  final int lfoIndex;
  final String paramId;
  final double amount;

  Map<String, dynamic> toJson() => {
        'lfoIndex': lfoIndex,
        'paramId': paramId,
        'amount': amount,
      };
}

class SubtractiveSynthPreset {
  const SubtractiveSynthPreset({
    required this.params,
    this.lfos = const [],
    this.mods = const [],
  });

  final Map<String, double> params;
  final List<SubtractivePresetLfo> lfos;
  final List<SubtractivePresetMod> mods;
}

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

  static const _quarterSine = SubtractivePresetLfo(waveform: 0, syncDivision: 3);
  static const _halfTri = SubtractivePresetLfo(waveform: 1, syncDivision: 2);
  static const _barSine = SubtractivePresetLfo(waveform: 0, syncDivision: 1);
  static const _eighthSine = SubtractivePresetLfo(waveform: 0, syncDivision: 4);
  static const _slowSaw = SubtractivePresetLfo(waveform: 2, syncDivision: 3);
  static const _sixteenthTri = SubtractivePresetLfo(waveform: 1, syncDivision: 5);
  static const _eighthSquare = SubtractivePresetLfo(waveform: 3, syncDivision: 4);
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
    'preset:synth-init': _bundle({
      'osc1Shape': 0.5,
      'osc2Shape': 0.5,
      'oscMix': 0.37,
      'filterCutoff': 0.75,
      'filterQ': 0.2,
    }),
    'preset:synth-pluck': _bundle({
      'osc1Shape': 0.5,
      'oscMix': 0.2,
      'filterCutoff': 0.85,
      'filterEnvAmount': 0.7,
      'filterAttack': 0.0,
      'filterDecay': 0.25,
      'attack': 0.0,
      'decay': 0.35,
      'sustain': 0.0,
      'release': 0.3,
    }),
    'preset:synth-noise-sweep': _bundle(
      {
        'noiseLevel': 0.45,
        'oscMix': 0.0,
        'filterCutoff': 0.35,
        'filterEnvAmount': 0.85,
        'filterAttack': 0.1,
        'filterDecay': 0.6,
        'attack': 0.05,
        'release': 0.5,
      },
      lfos: const [SubtractivePresetLfo(waveform: 2, syncDivision: 4, rate: 2.0)],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.55),
      ],
    ),

    // ── Bass (5) ──────────────────────────────────────────────────────────
    'preset:synth-bass-sub-foundation': _bundle({
      'osc1Shape': 0.0,
      'osc2Shape': 0.0,
      'oscMix': 0.0,
      'osc1Octave': 0.25,
      'filterCutoff': 0.28,
      'filterQ': 0.15,
      'filterMode': 5,
      'filterEnvAmount': 0.15,
      'attack': 0.01,
      'decay': 0.2,
      'sustain': 0.95,
      'release': 0.3,
      'synthMono': 1.0,
      'velocitySensitivity': 0.85,
    }),
    'preset:synth-bass-punch': _bundle({
      'osc1Shape': 0.75,
      'osc2Shape': 1.0,
      'oscMix': 0.42,
      'osc1Octave': 0.32,
      'filterCutoff': 0.38,
      'filterQ': 0.45,
      'filterEnvAmount': 0.72,
      'filterAttack': 0.0,
      'filterDecay': 0.22,
      'filterSustain': 0.12,
      'attack': 0.0,
      'decay': 0.42,
      'sustain': 0.55,
      'release': 0.28,
      'synthMono': 1.0,
    }),
    'preset:synth-bass-reese': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.5,
        'oscMix': 0.55,
        'osc1Octave': 0.3,
        'osc1Detune': 0.42,
        'osc2Detune': 0.58,
        'unisonVoices': 1.0,
        'unisonDetune': 0.62,
        'filterCutoff': 0.32,
        'filterQ': 0.28,
        'filterMode': 0,
        'filterEnvAmount': 0.25,
        'attack': 0.04,
        'sustain': 0.88,
        'release': 0.4,
        'glideMs': 0.04,
      },
      lfos: const [_quarterSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.42),
      ],
    ),
    'preset:synth-bass-warehouse': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.75,
        'osc2Semi': 0.09,
        'oscMix': 0.68,
        'oscMixMode': 2,
        'osc1Octave': 0.28,
        'filterCutoff': 0.26,
        'filterQ': 0.55,
        'filterEnvAmount': 0.48,
        'filterFm': 0.35,
        'filterDecay': 0.48,
        'attack': 0.02,
        'decay': 0.35,
        'sustain': 0.8,
        'release': 0.35,
        'preDrive': 0.22,
        'synthMono': 1.0,
      },
      lfos: const [_eighthSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.18),
      ],
    ),
    'preset:synth-bass-acid': _bundle({
      'osc1Shape': 0.5,
      'osc2Shape': 0.5,
      'oscMix': 0.5,
      'osc1Sync': 0.85,
      'osc1Octave': 0.34,
      'filterCutoff': 0.22,
      'filterQ': 0.78,
      'filterEnvAmount': 0.92,
      'filterAttack': 0.0,
      'filterDecay': 0.18,
      'filterSustain': 0.0,
      'filterRelease': 0.12,
      'attack': 0.0,
      'decay': 0.15,
      'sustain': 0.0,
      'release': 0.08,
      'synthMono': 1.0,
      'synthLegato': 1.0,
      'glideMs': 0.02,
    }),

    // ── Wobble & motion bass (5) ────────────────────────────────────────────
    'preset:synth-bass-wobble-classic': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.75,
        'oscMix': 0.55,
        'osc1Octave': 0.28,
        'filterCutoff': 0.3,
        'filterQ': 0.72,
        'filterMode': 5,
        'filterEnvAmount': 0.08,
        'attack': 0.0,
        'decay': 0.18,
        'sustain': 0.92,
        'release': 0.22,
        'preDrive': 0.15,
        'synthMono': 1.0,
        'velocitySensitivity': 0.8,
      },
      lfos: const [_quarterSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.65),
      ],
    ),
    'preset:synth-bass-wobble-fast': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 1.0,
        'oscMix': 0.48,
        'osc1Octave': 0.3,
        'filterCutoff': 0.26,
        'filterQ': 0.68,
        'filterEnvAmount': 0.05,
        'attack': 0.0,
        'sustain': 0.95,
        'release': 0.15,
        'synthMono': 1.0,
      },
      lfos: const [_sixteenthTri],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.58),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterQ', amount: 0.12),
      ],
    ),
    'preset:synth-bass-wobble-dub': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.5,
        'oscMix': 0.5,
        'osc1Octave': 0.26,
        'filterCutoff': 0.24,
        'filterQ': 0.75,
        'filterMode': 5,
        'filterEnvAmount': 0.0,
        'filterDrive': 0.18,
        'attack': 0.0,
        'decay': 0.12,
        'sustain': 0.98,
        'release': 0.1,
        'preDrive': 0.28,
        'synthMono': 1.0,
      },
      lfos: const [_eighthSquare],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.72),
      ],
    ),
    'preset:synth-bass-wobble-growl': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.75,
        'osc2Semi': 0.09,
        'oscMix': 0.62,
        'oscMixMode': 2,
        'osc1Octave': 0.27,
        'filterCutoff': 0.28,
        'filterQ': 0.62,
        'filterEnvAmount': 0.1,
        'filterFm': 0.2,
        'filterDrive': 0.22,
        'attack': 0.0,
        'sustain': 0.9,
        'release': 0.2,
        'preDrive': 0.32,
        'synthMono': 1.0,
      },
      lfos: const [
        _quarterSine,
        _eighthSine,
      ],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.55),
        SubtractivePresetMod(lfoIndex: 1, paramId: 'filterFm', amount: 0.38),
        SubtractivePresetMod(lfoIndex: 1, paramId: 'filterDrive', amount: 0.15),
      ],
    ),
    'preset:synth-bass-wobble-talk': _bundle(
      {
        'osc1Shape': 0.25,
        'osc2Shape': 0.5,
        'oscMix': 0.4,
        'osc1Octave': 0.32,
        'filterCutoff': 0.34,
        'filterQ': 0.55,
        'filterEnvAmount': 0.12,
        'attack': 0.02,
        'sustain': 0.88,
        'release': 0.25,
        'synthMono': 1.0,
        'synthLegato': 1.0,
        'glideMs': 0.03,
      },
      lfos: const [_halfSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.48),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'osc1Detune', amount: 0.08),
      ],
    ),

    // ── Motion leads & FX (3) ───────────────────────────────────────────────
    'preset:synth-lead-wobble': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.5,
        'oscMix': 0.45,
        'filterCutoff': 0.62,
        'filterQ': 0.52,
        'filterEnvAmount': 0.35,
        'attack': 0.0,
        'decay': 0.2,
        'sustain': 0.75,
        'release': 0.2,
        'glideMs': 0.05,
      },
      lfos: const [_eighthSquare],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.45),
      ],
    ),
    'preset:synth-lead-siren': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.25,
        'oscMix': 0.6,
        'osc1Sync': 0.7,
        'filterCutoff': 0.55,
        'filterQ': 0.65,
        'filterEnvAmount': 0.2,
        'attack': 0.0,
        'sustain': 0.85,
        'release': 0.15,
        'glideMs': 0.08,
      },
      lfos: const [SubtractivePresetLfo(waveform: 2, syncDivision: 2, rate: 1.5)],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.52),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'osc1Sync', amount: 0.18),
      ],
    ),
    'preset:synth-fx-riser-noise': _bundle(
      {
        'noiseLevel': 0.55,
        'oscMix': 0.08,
        'osc1Shape': 0.5,
        'filterCutoff': 0.22,
        'filterQ': 0.35,
        'filterEnvAmount': 0.4,
        'filterAttack': 0.0,
        'filterDecay': 0.8,
        'attack': 0.02,
        'decay': 0.6,
        'sustain': 0.3,
        'release': 0.5,
      },
      lfos: const [_barSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.62),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'noiseLevel', amount: 0.2),
      ],
    ),

    // ── Pads (5) ──────────────────────────────────────────────────────────
    'preset:synth-pad-warm': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.12,
        'oscMix': 0.62,
        'unisonVoices': 0.66,
        'unisonDetune': 0.42,
        'filterCutoff': 0.52,
        'filterQ': 0.18,
        'filterEnvAmount': 0.38,
        'filterAttack': 0.18,
        'filterDecay': 0.55,
        'attack': 0.42,
        'decay': 0.35,
        'sustain': 0.88,
        'release': 0.72,
        'glideMs': 0.18,
        'synthLegato': 1.0,
        'velocitySensitivity': 0.7,
      },
      lfos: const [_quarterSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.24),
      ],
    ),
    'preset:synth-pad-glass': _bundle(
      {
        'osc1Shape': 0.08,
        'osc2Shape': 0.25,
        'osc2Semi': 0.18,
        'oscMix': 0.55,
        'filterCutoff': 0.74,
        'filterQ': 0.1,
        'filterEnvAmount': 0.18,
        'attack': 0.55,
        'decay': 0.28,
        'sustain': 0.92,
        'release': 0.8,
        'velocitySensitivity': 0.55,
      },
      lfos: const [_halfTri],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.16),
      ],
    ),
    'preset:synth-pad-choir': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.5,
        'osc2Semi': 0.09,
        'oscMix': 0.5,
        'unisonVoices': 1.0,
        'unisonDetune': 0.58,
        'filterCutoff': 0.48,
        'filterQ': 0.22,
        'filterEnvAmount': 0.3,
        'filterAttack': 0.22,
        'filterDecay': 0.5,
        'attack': 0.48,
        'sustain': 0.9,
        'release': 0.85,
        'glideMs': 0.12,
        'synthLegato': 1.0,
      },
      lfos: const [_barSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.2),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'unisonDetune', amount: 0.08),
      ],
    ),
    'preset:synth-pad-dark': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.75,
        'oscMix': 0.45,
        'osc1Octave': 0.42,
        'filterCutoff': 0.32,
        'filterQ': 0.35,
        'filterMode': 0,
        'filterEnvAmount': 0.45,
        'filterAttack': 0.35,
        'filterDecay': 0.62,
        'attack': 0.38,
        'decay': 0.4,
        'sustain': 0.85,
        'release': 0.78,
        'noiseLevel': 0.06,
      },
      lfos: const [_slowSaw],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.32),
      ],
    ),
    'preset:synth-pad-lofi': _bundle(
      {
        'osc1Shape': 0.25,
        'osc2Shape': 0.5,
        'oscMix': 0.48,
        'noiseLevel': 0.12,
        'filterCutoff': 0.38,
        'filterQ': 0.42,
        'filterMode': 0,
        'filterEnvAmount': 0.28,
        'attack': 0.25,
        'decay': 0.45,
        'sustain': 0.8,
        'release': 0.55,
        'preDrive': 0.12,
        'velocitySensitivity': 0.65,
      },
      lfos: const [_eighthSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.22),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'noiseLevel', amount: 0.06),
      ],
    ),
    'preset:synth-warm-pad': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.12,
        'oscMix': 0.62,
        'unisonVoices': 0.66,
        'unisonDetune': 0.42,
        'filterCutoff': 0.52,
        'filterQ': 0.18,
        'filterEnvAmount': 0.38,
        'filterAttack': 0.18,
        'filterDecay': 0.55,
        'attack': 0.42,
        'decay': 0.35,
        'sustain': 0.88,
        'release': 0.72,
        'glideMs': 0.18,
        'synthLegato': 1.0,
        'velocitySensitivity': 0.7,
      },
      lfos: const [_quarterSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.24),
      ],
    ),

    // ── Leads (5) ─────────────────────────────────────────────────────────
    'preset:synth-lead-saw': _bundle({
      'osc1Shape': 0.5,
      'osc2Shape': 0.5,
      'oscMix': 0.35,
      'filterCutoff': 0.82,
      'filterQ': 0.32,
      'filterEnvAmount': 0.58,
      'filterDecay': 0.28,
      'attack': 0.02,
      'decay': 0.22,
      'sustain': 0.72,
      'release': 0.25,
      'glideMs': 0.06,
    }),
    'preset:synth-lead-sync': _bundle({
      'osc1Shape': 0.5,
      'osc2Shape': 0.25,
      'oscMix': 0.62,
      'osc1Sync': 0.92,
      'osc2Octave': 0.62,
      'filterCutoff': 0.78,
      'filterQ': 0.48,
      'filterEnvAmount': 0.65,
      'filterAttack': 0.0,
      'filterDecay': 0.2,
      'attack': 0.0,
      'decay': 0.18,
      'sustain': 0.65,
      'release': 0.18,
      'glideMs': 0.05,
    }),
    'preset:synth-lead-silk': _bundle(
      {
        'osc1Shape': 0.0,
        'osc2Shape': 0.12,
        'oscMix': 0.58,
        'osc2Semi': 0.36,
        'filterCutoff': 0.68,
        'filterQ': 0.12,
        'filterEnvAmount': 0.22,
        'attack': 0.12,
        'decay': 0.3,
        'sustain': 0.82,
        'release': 0.45,
        'velocitySensitivity': 0.75,
      },
      lfos: const [_barSine],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.14),
      ],
    ),
    'preset:synth-lead-wide': _bundle(
      {
        'osc1Shape': 0.5,
        'osc2Shape': 0.5,
        'oscMix': 0.48,
        'osc1Detune': 0.46,
        'osc2Detune': 0.54,
        'unisonVoices': 0.66,
        'unisonDetune': 0.55,
        'filterCutoff': 0.76,
        'filterQ': 0.25,
        'filterEnvAmount': 0.42,
        'attack': 0.03,
        'sustain': 0.78,
        'release': 0.32,
        'glideMs': 0.14,
        'synthLegato': 1.0,
      },
      lfos: const [SubtractivePresetLfo(waveform: 1, syncDivision: 4)],
      mods: const [
        SubtractivePresetMod(lfoIndex: 0, paramId: 'osc1Detune', amount: 0.1),
        SubtractivePresetMod(lfoIndex: 0, paramId: 'osc2Detune', amount: -0.1),
      ],
    ),
    'preset:synth-lead-bite': _bundle({
      'osc1Shape': 1.0,
      'osc2Shape': 0.75,
      'oscMix': 0.4,
      'oscMixMode': 1,
      'filterCutoff': 0.7,
      'filterQ': 0.52,
      'filterEnvAmount': 0.75,
      'filterAttack': 0.0,
      'filterDecay': 0.24,
      'filterDrive': 0.28,
      'attack': 0.0,
      'decay': 0.28,
      'sustain': 0.6,
      'release': 0.2,
      'preDrive': 0.18,
      'glideMs': 0.04,
    }),
  };
}
