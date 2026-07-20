part of 'bass_synth_presets.dart';

/// Round 2 — more styles + layering companions (HP / mid / click / air).
final Map<String, BassSynthPreset> _bassPresetsGroup3 = {
  // 21 — pure sub floor for stacks
  'preset:bass-layer-sub-floor': BassSynthPresets._bundle({
    'bassOscShape': 0.04,
    'bassSubMix': 0.95,
    'bassSubOctave': 1.0,
    'bassOctave': 1.0,
    'bassFilterResonance': 0.08,
    'filterCutoff': 0.28,
    'filterEnvAmount': 0.05,
    'attack': 0.02,
    'sustain': 1.0,
    'release': 0.5,
    'bassVelocitySense': 0.4,
  }, audioFx: [
    _BassFx.filter(id: 'fx-lp', cutoff: 0.32, resonance: 0.1),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.5, ratio: 0.4, makeup: 0.2),
  ]),

  // 22 — mid growl over a sub (HP removes boom)
  'preset:bass-layer-mid-growl': BassSynthPresets._bundle({
    'bassOscShape': 0.68,
    'bassSubMix': 0.15,
    'bassNoise': 0.12,
    'bassDrive': 0.55,
    'bassSquash': 0.3,
    'bassFilterResonance': 0.45,
    'filterCutoff': 0.42,
    'filterEnvAmount': 0.4,
    'sustain': 0.9,
    'release': 0.4,
  }, lfos: const [
    BassSynthPresets._barSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.3),
  ], audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.28, resonance: 0.2, mode: 0.35),
    _BassFx.distortion(id: 'fx-dist', drive: 0.6, tone: 0.4, mix: 0.7),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.3),
  ]),

  // 23 — high bite / octave sparkle layer
  'preset:bass-layer-high-bite': BassSynthPresets._bundle({
    'bassOscShape': 0.75,
    'bassSubMix': 0.1,
    'bassOctave': 3.0,
    'bassFilterResonance': 0.4,
    'bassDrive': 0.25,
    'filterCutoff': 0.65,
    'filterEnvAmount': 0.7,
    'filterDecay': 0.25,
    'attack': 0.0,
    'sustain': 0.4,
    'release': 0.22,
  }, audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.4, resonance: 0.25, mode: 0.35),
    _BassFx.bitcrusher(id: 'fx-crush', rate: 0.55, bits: 8.0, mix: 0.25),
  ]),

  // 24 — transient click / noise attack layer
  'preset:bass-layer-click': BassSynthPresets._bundle({
    'bassOscShape': 0.5,
    'bassSubMix': 0.2,
    'bassNoise': 0.75,
    'bassDrive': 0.35,
    'bassFilterResonance': 0.35,
    'filterCutoff': 0.7,
    'filterEnvAmount': 0.85,
    'filterDecay': 0.12,
    'attack': 0.0,
    'sustain': 0.05,
    'release': 0.12,
  }, audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.45, resonance: 0.15, mode: 0.35),
    _BassFx.distortion(id: 'fx-dist', drive: 0.45, tone: 0.7, mix: 0.5),
  ]),

  // 25 — airy chorus top layer
  'preset:bass-layer-air-chorus': BassSynthPresets._bundle({
    'bassOscShape': 0.35,
    'bassSubMix': 0.12,
    'bassOctave': 3.0,
    'bassFilterResonance': 0.2,
    'filterCutoff': 0.7,
    'filterEnvAmount': 0.25,
    'attack': 0.08,
    'sustain': 0.85,
    'release': 0.55,
  }, lfos: const [
    BassSynthPresets._slowSaw,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.18),
  ], audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.42, resonance: 0.12, mode: 0.35),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.65),
    _BassFx.delay(id: 'fx-delay', timeMs: 280.0, feedback: 0.2, mix: 0.15),
  ]),

  // 26 — mid grit / dirt over clean sub
  'preset:bass-layer-grit': BassSynthPresets._bundle({
    'bassOscShape': 0.6,
    'bassSubMix': 0.2,
    'bassNoise': 0.15,
    'bassDrive': 0.7,
    'bassSquash': 0.45,
    'filterCutoff': 0.45,
    'filterEnvAmount': 0.3,
    'sustain': 0.85,
    'release': 0.35,
  }, audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.25, resonance: 0.15, mode: 0.35),
    _BassFx.distortion(id: 'fx-dist', drive: 0.75, tone: 0.3, mix: 0.8),
    _BassFx.bitcrusher(id: 'fx-crush', rate: 0.35, bits: 6.0, mix: 0.3),
  ]),

  // 27 — wobble mid only (stack under with Sub Floor)
  'preset:bass-layer-wobble-mid': BassSynthPresets._bundle({
    'bassOscShape': 0.58,
    'bassSubMix': 0.18,
    'bassDrive': 0.4,
    'bassFilterResonance': 0.55,
    'filterCutoff': 0.4,
    'filterEnvAmount': 0.15,
    'sustain': 0.95,
    'release': 0.35,
  }, lfos: const [
    BassSynthPresets._quarterSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.65),
  ], audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.26, resonance: 0.18, mode: 0.35),
    _BassFx.distortion(id: 'fx-dist', drive: 0.5, tone: 0.45, mix: 0.6),
  ]),

  // 28 — wide reese mid layer
  'preset:bass-layer-reese-spread': BassSynthPresets._bundle({
    'bassOscShape': 0.52,
    'bassSubMix': 0.2,
    'bassNoise': 0.1,
    'bassDrive': 0.35,
    'bassFilterResonance': 0.35,
    'filterCutoff': 0.4,
    'sustain': 0.95,
    'release': 0.5,
  }, lfos: const [
    BassSynthPresets._halfTri,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.22),
  ], audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.24, resonance: 0.15, mode: 0.35),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.55),
    _BassFx.phaser(id: 'fx-phaser', mix: 0.25),
  ]),

  // 29 — talking / formant-ish noise layer
  'preset:bass-layer-talk': BassSynthPresets._bundle({
    'bassOscShape': 0.45,
    'bassSubMix': 0.15,
    'bassNoise': 0.45,
    'bassDrive': 0.3,
    'bassFilterResonance': 0.65,
    'filterCutoff': 0.48,
    'filterEnvAmount': 0.35,
    'sustain': 0.8,
    'release': 0.4,
  }, lfos: const [
    BassSynthPresets._eighthSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.5),
    BassPresetMod(lfoIndex: 0, paramId: 'bassFilterResonance', amount: 0.2),
  ], audioFx: [
    _BassFx.filter(id: 'fx-bp', cutoff: 0.45, resonance: 0.5, mode: 0.67),
    _BassFx.distortion(id: 'fx-dist', drive: 0.4, tone: 0.55, mix: 0.45),
  ]),

  // 30 — soft pad layer over bass notes
  'preset:bass-layer-soft-pad': BassSynthPresets._bundle({
    'bassOscShape': 0.25,
    'bassSubMix': 0.2,
    'bassOctave': 3.0,
    'bassFilterResonance': 0.15,
    'filterCutoff': 0.6,
    'filterEnvAmount': 0.2,
    'attack': 0.5,
    'sustain': 0.95,
    'release': 0.75,
    'bassVelocitySense': 0.45,
  }, lfos: const [
    BassSynthPresets._slowSaw,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.15),
  ], audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.35, resonance: 0.1, mode: 0.35),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.5),
    _BassFx.delay(id: 'fx-delay', timeMs: 450.0, feedback: 0.3, mix: 0.22),
  ]),

  // 31 — future bass pluck
  'preset:bass-future-pluck': BassSynthPresets._bundle({
    'bassOscShape': 0.55,
    'bassSubMix': 0.45,
    'bassDrive': 0.2,
    'bassFilterResonance': 0.35,
    'filterCutoff': 0.55,
    'filterEnvAmount': 0.8,
    'filterDecay': 0.2,
    'attack': 0.0,
    'sustain': 0.25,
    'release': 0.28,
  }, audioFx: [
    _BassFx.chorus(id: 'fx-chorus', mix: 0.35),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.45, ratio: 0.55, makeup: 0.3),
  ]),

  // 32 — drill slide growl
  'preset:bass-drill-slide': BassSynthPresets._bundle({
    'bassOscShape': 0.7,
    'bassSubMix': 0.55,
    'bassSubOctave': 1.0,
    'bassDrive': 0.55,
    'bassSquash': 0.4,
    'bassFilterResonance': 0.45,
    'filterCutoff': 0.35,
    'filterEnvAmount': 0.55,
    'filterDecay': 0.5,
    'attack': 0.0,
    'sustain': 0.5,
    'release': 0.55,
    'glideMs': 0.65,
  }, audioFx: [
    _BassFx.distortion(id: 'fx-dist', drive: 0.65, tone: 0.35, mix: 0.7),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.4, ratio: 0.7, makeup: 0.4),
  ]),

  // 33 — lo-fi tape bass
  'preset:bass-lofi-tape': BassSynthPresets._bundle({
    'bassOscShape': 0.4,
    'bassSubMix': 0.55,
    'bassNoise': 0.08,
    'bassDrive': 0.25,
    'bassFilterResonance': 0.25,
    'filterCutoff': 0.42,
    'filterEnvAmount': 0.35,
    'attack': 0.03,
    'sustain': 0.7,
    'release': 0.4,
  }, audioFx: [
    _BassFx.bitcrusher(id: 'fx-crush', rate: 0.42, bits: 7.0, mix: 0.4),
    _BassFx.filter(id: 'fx-lp', cutoff: 0.48, resonance: 0.2),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.2),
  ]),

  // 34 — reggae / dub one-drop body
  'preset:bass-reggae-drop': BassSynthPresets._bundle({
    'bassOscShape': 0.3,
    'bassSubMix': 0.7,
    'bassSubOctave': 1.0,
    'bassDrive': 0.15,
    'bassFilterResonance': 0.22,
    'filterCutoff': 0.4,
    'filterEnvAmount': 0.45,
    'filterDecay': 0.35,
    'attack': 0.02,
    'sustain': 0.55,
    'release': 0.35,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.5, ratio: 0.5, makeup: 0.25),
    _BassFx.delay(id: 'fx-delay', timeMs: 390.0, feedback: 0.25, mix: 0.12),
  ]),

  // 35 — house filtered pluck
  'preset:bass-house-pluck': BassSynthPresets._bundle({
    'bassOscShape': 0.48,
    'bassSubMix': 0.5,
    'bassFilterResonance': 0.4,
    'bassDrive': 0.18,
    'filterCutoff': 0.45,
    'filterEnvAmount': 0.75,
    'filterDecay': 0.22,
    'attack': 0.0,
    'sustain': 0.3,
    'release': 0.22,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.48, ratio: 0.6, makeup: 0.3),
  ]),

  // 36 — breakbeat mid rumble
  'preset:bass-break-rumble': BassSynthPresets._bundle({
    'bassOscShape': 0.55,
    'bassSubMix': 0.4,
    'bassNoise': 0.12,
    'bassDrive': 0.4,
    'bassSquash': 0.25,
    'bassFilterResonance': 0.35,
    'filterCutoff': 0.38,
    'filterEnvAmount': 0.5,
    'filterDecay': 0.4,
    'attack': 0.0,
    'sustain': 0.6,
    'release': 0.35,
  }, lfos: const [
    BassSynthPresets._eighthSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'bassDrive', amount: 0.15),
  ], audioFx: [
    _BassFx.distortion(id: 'fx-dist', drive: 0.5, tone: 0.4, mix: 0.55),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.42, ratio: 0.65, makeup: 0.35),
  ]),

  // 37 — melodic mid bass (playable lines / chords under)
  'preset:bass-melodic-mid': BassSynthPresets._bundle({
    'bassOscShape': 0.4,
    'bassSubMix': 0.25,
    'bassOctave': 2.0,
    'bassFilterResonance': 0.28,
    'bassDrive': 0.15,
    'filterCutoff': 0.55,
    'filterEnvAmount': 0.45,
    'attack': 0.04,
    'sustain': 0.75,
    'release': 0.4,
    'bassVelocitySense': 0.85,
  }, audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.22, resonance: 0.12, mode: 0.35),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.3),
  ]),

  // 38 — hollow scooped body (stack with Mid Growl)
  'preset:bass-layer-hollow': BassSynthPresets._bundle({
    'bassOscShape': 0.35,
    'bassSubMix': 0.75,
    'bassSubOctave': 1.0,
    'bassFilterResonance': 0.15,
    'filterCutoff': 0.35,
    'filterEnvAmount': 0.2,
    'attack': 0.02,
    'sustain': 0.95,
    'release': 0.45,
  }, audioFx: [
    _BassFx.filter(id: 'fx-lp', cutoff: 0.35, resonance: 0.12),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.55, ratio: 0.4, makeup: 0.2),
  ]),

  // 39 — sidechain-friendly pump body (short sustain)
  'preset:bass-layer-pump': BassSynthPresets._bundle({
    'bassOscShape': 0.32,
    'bassSubMix': 0.65,
    'bassDrive': 0.2,
    'bassFilterResonance': 0.25,
    'filterCutoff': 0.42,
    'filterEnvAmount': 0.55,
    'filterDecay': 0.2,
    'attack': 0.0,
    'sustain': 0.25,
    'release': 0.2,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.4, ratio: 0.75, makeup: 0.4),
  ]),

  // 40 — ring sparkle layer over sub
  'preset:bass-layer-ring-spark': BassSynthPresets._bundle({
    'bassOscShape': 0.4,
    'bassSubMix': 0.15,
    'bassOctave': 3.0,
    'bassNoise': 0.08,
    'bassDrive': 0.2,
    'filterCutoff': 0.6,
    'filterEnvAmount': 0.35,
    'sustain': 0.7,
    'release': 0.4,
  }, lfos: const [
    BassSynthPresets._sixteenthTri,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.2),
  ], audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.4, resonance: 0.2, mode: 0.35),
    _BassFx.ringMod(id: 'fx-ring', shift: 0.64, mix: 0.45, tone: 0.75),
  ]),
};
