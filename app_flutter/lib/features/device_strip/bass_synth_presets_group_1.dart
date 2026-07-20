part of 'bass_synth_presets.dart';

final Map<String, BassSynthPreset> _bassPresetsGroup1 = {
  // 1 — clean sine/sub foundation
  'preset:bass-sub-foundation': BassSynthPresets._bundle({
    'bassOscShape': 0.08,
    'bassSubMix': 0.72,
    'bassSubOctave': 1.0,
    'bassFilterResonance': 0.12,
    'filterCutoff': 0.42,
    'filterEnvAmount': 0.15,
    'filterDecay': 0.55,
    'attack': 0.01,
    'sustain': 0.95,
    'release': 0.45,
  }),

  // 2 — long booming 808 with glue + grit
  'preset:bass-808-boom': BassSynthPresets._bundle({
    'bassOscShape': 0.12,
    'bassSubMix': 0.85,
    'bassSubOctave': 1.0,
    'bassOctave': 1.0,
    'bassDrive': 0.22,
    'bassSquash': 0.35,
    'filterCutoff': 0.38,
    'filterEnvAmount': 0.55,
    'filterDecay': 0.72,
    'attack': 0.0,
    'sustain': 0.55,
    'release': 0.85,
    'bassVelocitySense': 0.7,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.4, ratio: 0.7, makeup: 0.35),
    _BassFx.distortion(id: 'fx-dist', drive: 0.35, tone: 0.3, mix: 0.4),
  ]),

  // 3 — acid 303: high Q + env + distortion
  'preset:bass-acid-303': BassSynthPresets._bundle({
    'bassOscShape': 0.72,
    'bassSubMix': 0.25,
    'bassFilterResonance': 0.78,
    'bassDrive': 0.15,
    'filterCutoff': 0.28,
    'filterEnvAmount': 0.9,
    'filterDecay': 0.35,
    'attack': 0.0,
    'sustain': 0.35,
    'release': 0.22,
    'glideMs': 0.18,
  }, audioFx: [
    _BassFx.distortion(id: 'fx-acid-dist', drive: 0.62, tone: 0.55, mix: 0.75),
  ]),

  // 4 — reese-ish growl: noise + chorus + slow LFO
  'preset:bass-reese-growl': BassSynthPresets._bundle({
    'bassOscShape': 0.55,
    'bassSubMix': 0.45,
    'bassSubOctave': 1.0,
    'bassNoise': 0.18,
    'bassDrive': 0.4,
    'bassSquash': 0.25,
    'bassFilterResonance': 0.4,
    'filterCutoff': 0.32,
    'filterEnvAmount': 0.35,
    'filterDecay': 0.6,
    'sustain': 0.9,
    'release': 0.5,
  }, lfos: const [
    BassSynthPresets._barSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.28),
    BassPresetMod(lfoIndex: 0, paramId: 'bassDrive', amount: 0.12),
  ], audioFx: [
    _BassFx.chorus(id: 'fx-chorus', mix: 0.4),
    _BassFx.distortion(id: 'fx-dist', drive: 0.5, tone: 0.35, mix: 0.55),
  ]),

  // 5 — dubstep wobble
  'preset:bass-dub-wobble': BassSynthPresets._bundle({
    'bassOscShape': 0.62,
    'bassSubMix': 0.55,
    'bassSubOctave': 1.0,
    'bassDrive': 0.45,
    'bassFilterResonance': 0.55,
    'filterCutoff': 0.35,
    'filterEnvAmount': 0.2,
    'sustain': 0.95,
    'release': 0.4,
  }, lfos: const [
    BassSynthPresets._quarterSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.7),
    BassPresetMod(lfoIndex: 0, paramId: 'bassFilterResonance', amount: 0.25),
  ], audioFx: [
    _BassFx.distortion(id: 'fx-dist', drive: 0.58, tone: 0.4, mix: 0.7),
    _BassFx.chorus(id: 'fx-chorus', mix: 0.25),
  ]),

  // 6 — warehouse techno punch
  'preset:bass-warehouse': BassSynthPresets._bundle({
    'bassOscShape': 0.48,
    'bassSubMix': 0.6,
    'bassDrive': 0.28,
    'bassFilterResonance': 0.3,
    'filterCutoff': 0.4,
    'filterEnvAmount': 0.7,
    'filterDecay': 0.28,
    'attack': 0.0,
    'sustain': 0.45,
    'release': 0.25,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.5, ratio: 0.55, makeup: 0.3),
    _BassFx.distortion(id: 'fx-dist', drive: 0.4, tone: 0.5, mix: 0.45),
  ]),

  // 7 — moog-ish funk with glide
  'preset:bass-moog-funk': BassSynthPresets._bundle({
    'bassOscShape': 0.42,
    'bassSubMix': 0.4,
    'bassFilterResonance': 0.45,
    'bassDrive': 0.18,
    'filterCutoff': 0.48,
    'filterEnvAmount': 0.65,
    'filterDecay': 0.4,
    'attack': 0.02,
    'sustain': 0.7,
    'release': 0.3,
    'glideMs': 0.35,
  }, audioFx: [
    _BassFx.filter(id: 'fx-hp', cutoff: 0.18, resonance: 0.15, mode: 0.35),
  ]),

  // 8 — neuro / DnB aggression
  'preset:bass-neuro-dnb': BassSynthPresets._bundle({
    'bassOscShape': 0.7,
    'bassSubMix': 0.35,
    'bassNoise': 0.22,
    'bassDrive': 0.65,
    'bassSquash': 0.4,
    'bassFilterResonance': 0.5,
    'filterCutoff': 0.3,
    'filterEnvAmount': 0.45,
    'sustain': 0.85,
    'release': 0.35,
  }, lfos: const [
    BassSynthPresets._eighthSine,
    BassSynthPresets._sixteenthTri,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.55),
    BassPresetMod(lfoIndex: 1, paramId: 'bassDrive', amount: 0.2),
  ], audioFx: [
    _BassFx.distortion(id: 'fx-dist', drive: 0.75, tone: 0.28, mix: 0.8),
    _BassFx.bitcrusher(id: 'fx-crush', rate: 0.4, bits: 5.0, mix: 0.35),
  ]),

  // 9 — trap slide 808
  'preset:bass-trap-slide': BassSynthPresets._bundle({
    'bassOscShape': 0.15,
    'bassSubMix': 0.9,
    'bassSubOctave': 1.0,
    'bassOctave': 1.0,
    'bassSquash': 0.55,
    'bassDrive': 0.2,
    'filterCutoff': 0.35,
    'filterEnvAmount': 0.5,
    'filterDecay': 0.65,
    'attack': 0.0,
    'sustain': 0.4,
    'release': 0.75,
    'glideMs': 0.55,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.35, ratio: 0.75, makeup: 0.45),
  ]),

  // 10 — ambient soft bass pad
  'preset:bass-ambient-pad': BassSynthPresets._bundle({
    'bassOscShape': 0.2,
    'bassSubMix': 0.55,
    'bassFilterResonance': 0.2,
    'filterCutoff': 0.55,
    'filterEnvAmount': 0.25,
    'attack': 0.45,
    'sustain': 0.95,
    'release': 0.8,
    'bassVelocitySense': 0.5,
  }, lfos: const [
    BassSynthPresets._slowSaw,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.2),
  ], audioFx: [
    _BassFx.chorus(id: 'fx-chorus', mix: 0.45),
    _BassFx.delay(id: 'fx-delay', timeMs: 520.0, feedback: 0.35, mix: 0.2),
  ]),
};
