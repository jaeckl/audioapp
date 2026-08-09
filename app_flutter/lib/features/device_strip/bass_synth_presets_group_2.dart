part of 'bass_synth_presets.dart';

final Map<String, BassSynthPreset> _bassPresetsGroup2 = {
  // 11 — disco octave bass
  'preset:bass-disco-octave': BassSynthPresets._bundle({
    'bassOscShape': 0.55,
    'bassSubMix': 0.35,
    'bassSubOctave': 1.0,
    'bassOctave': 3.0,
    'bassFilterResonance': 0.28,
    'filterCutoff': 0.62,
    'filterEnvAmount': 0.55,
    'filterDecay': 0.3,
    'attack': 0.01,
    'sustain': 0.65,
    'release': 0.28,
  }, audioFx: [
    _BassFx.chorus(id: 'fx-chorus', mix: 0.4),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.5, ratio: 0.5, makeup: 0.25),
  ]),

  // 12 — synthwave / retrowave
  'preset:bass-synthwave': BassSynthPresets._bundle({
    'bassOscShape': 0.5,
    'bassSubMix': 0.5,
    'bassDrive': 0.25,
    'bassFilterResonance': 0.35,
    'filterCutoff': 0.45,
    'filterEnvAmount': 0.4,
    'attack': 0.05,
    'sustain': 0.85,
    'release': 0.45,
  }, lfos: const [
    BassSynthPresets._halfTri,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.3),
  ], audioFx: [
    _BassFx.chorus(id: 'fx-chorus', mix: 0.5),
    _BassFx.phaser(id: 'fx-phaser', mix: 0.35),
  ]),

  // 13 — industrial dirt
  'preset:bass-industrial': BassSynthPresets._bundle({
    'bassOscShape': 0.8,
    'bassSubMix': 0.3,
    'bassNoise': 0.35,
    'bassDrive': 0.7,
    'bassSquash': 0.5,
    'bassFilterResonance': 0.4,
    'filterCutoff': 0.35,
    'filterEnvAmount': 0.3,
    'sustain': 0.8,
    'release': 0.35,
  }, audioFx: [
    _BassFx.bitcrusher(id: 'fx-crush', rate: 0.28, bits: 4.0, mix: 0.55),
    _BassFx.distortion(id: 'fx-dist', drive: 0.8, tone: 0.25, mix: 0.7),
  ]),

  // 14 — soft jazz-ish upright character
  'preset:bass-jazz-upright': BassSynthPresets._bundle({
    'bassOscShape': 0.22,
    'bassSubMix': 0.65,
    'bassNoise': 0.06,
    'bassFilterResonance': 0.18,
    'filterCutoff': 0.5,
    'filterEnvAmount': 0.35,
    'filterDecay': 0.45,
    'attack': 0.03,
    'sustain': 0.55,
    'release': 0.4,
    'bassVelocitySense': 1.0,
  }),

  // 15 — boom-bap hip-hop punch
  'preset:bass-boom-bap': BassSynthPresets._bundle({
    'bassOscShape': 0.28,
    'bassSubMix': 0.7,
    'bassSubOctave': 1.0,
    'bassDrive': 0.3,
    'bassSquash': 0.2,
    'filterCutoff': 0.4,
    'filterEnvAmount': 0.75,
    'filterDecay': 0.22,
    'attack': 0.0,
    'sustain': 0.35,
    'release': 0.28,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.42, ratio: 0.7, makeup: 0.4),
    _BassFx.distortion(id: 'fx-dist', drive: 0.38, tone: 0.4, mix: 0.4),
  ]),

  // 16 — minimal techno pulse (square LFO)
  'preset:bass-minimal-pulse': BassSynthPresets._bundle({
    'bassOscShape': 0.35,
    'bassSubMix': 0.55,
    'bassFilterResonance': 0.4,
    'filterCutoff': 0.38,
    'filterEnvAmount': 0.15,
    'attack': 0.0,
    'sustain': 0.9,
    'release': 0.2,
  }, lfos: const [
    BassSynthPresets._eighthSquare,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.45),
  ], audioFx: [
    _BassFx.filter(id: 'fx-lp', cutoff: 0.55, resonance: 0.2),
  ]),

  // 17 — psytrance rolling
  'preset:bass-psy-roll': BassSynthPresets._bundle({
    'bassOscShape': 0.65,
    'bassSubMix': 0.4,
    'bassDrive': 0.35,
    'bassFilterResonance': 0.7,
    'filterCutoff': 0.32,
    'filterEnvAmount': 0.25,
    'attack': 0.0,
    'sustain': 0.95,
    'release': 0.18,
  }, lfos: const [
    BassSynthPresets._sixteenthTri,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.6),
    BassPresetMod(lfoIndex: 0, paramId: 'bassFilterResonance', amount: 0.2),
  ], audioFx: [
    _BassFx.distortion(id: 'fx-dist', drive: 0.55, tone: 0.5, mix: 0.6),
  ]),

  // 18 — UK garage warm
  'preset:bass-uk-garage': BassSynthPresets._bundle({
    'bassOscShape': 0.38,
    'bassSubMix': 0.58,
    'bassDrive': 0.2,
    'bassFilterResonance': 0.28,
    'filterCutoff': 0.48,
    'filterEnvAmount': 0.5,
    'filterDecay': 0.35,
    'attack': 0.01,
    'sustain': 0.6,
    'release': 0.32,
    'glideMs': 0.12,
  }, audioFx: [
    _BassFx.chorus(id: 'fx-chorus', mix: 0.28),
    _BassFx.compressor(id: 'fx-comp', threshold: 0.48, ratio: 0.55, makeup: 0.3),
  ]),

  // 19 — metallic ring-mod character
  'preset:bass-metallic-ring': BassSynthPresets._bundle({
    'bassOscShape': 0.45,
    'bassSubMix': 0.4,
    'bassNoise': 0.1,
    'bassDrive': 0.3,
    'bassFilterResonance': 0.35,
    'filterCutoff': 0.5,
    'filterEnvAmount': 0.4,
    'sustain': 0.75,
    'release': 0.4,
  }, lfos: const [
    BassSynthPresets._quarterSine,
  ], mods: const [
    BassPresetMod(lfoIndex: 0, paramId: 'filterCutoff', amount: 0.25),
  ], audioFx: [
    _BassFx.ringMod(id: 'fx-ring', shift: 0.62, mix: 0.4, tone: 0.65),
    _BassFx.filter(id: 'fx-lp', cutoff: 0.5, resonance: 0.25),
  ]),

  // 20 — soft sine sub with glue
  'preset:bass-soft-sine': BassSynthPresets._bundle({
    'bassOscShape': 0.05,
    'bassSubMix': 0.8,
    'bassSubOctave': 1.0,
    'bassFilterResonance': 0.1,
    'filterCutoff': 0.4,
    'filterEnvAmount': 0.1,
    'attack': 0.04,
    'sustain': 0.95,
    'release': 0.55,
    'bassVelocitySense': 0.6,
  }, audioFx: [
    _BassFx.compressor(id: 'fx-comp', threshold: 0.55, ratio: 0.45, makeup: 0.25),
  ]),
};
