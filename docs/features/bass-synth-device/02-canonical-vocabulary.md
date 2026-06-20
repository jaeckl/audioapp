# Canonical Vocabulary: Bass Synth Device

## Binding table

| Concept | Canonical name | Type/file | Notes |
|---------|---------------|-----------|-------|
| Device type ID string | `kBasSynth = "bass_synth"` | `DeviceTypeIds.hpp` | `inline constexpr const char*` |
| Device type class | `BassSynthDeviceType` | `BassSynthDeviceType.hpp` | Inherits `IDeviceType` |
| Device instance struct | `BassSynthInstance` | `BassSynthInstance.hpp` | Holds 16 curated params |
| Instance variant entry | `BassSynthInstance` | `DeviceSlot.hpp` | Added to `DeviceInstance` `std::variant` |
| Device node kind enum | `DeviceNodeKind::BassSynth` | `DeviceChain.hpp` | Added to `DeviceNodeKind` enum |
| Live instrument kind | `LiveInstrumentKind::BassSynth` | `LivePerformance.hpp` | Added to `LiveInstrumentKind` enum |
| Playback params | `SubtractiveSynthParams` | `SubtractiveSynth.hpp` | Reuse existing — no new struct |
| Param kind (automation) | `ParamKind::BassSynth` | `AutomationTypes.hpp` | New enum entry |
| Bass param enum | `BassSynthParam` | `AutomationTypes.hpp` | New per-device param enum |
| Flutter strip widget | `BassSynthDeviceStrip` | `bass_synth_device_strip.dart` | Thin wrapper |
| Flutter panel widget | `BassSynthDevicePanel` | `bass_synth_device_panel.dart` | Full editor with tabs |
| Flutter panel density | `BassPanelDensity` | `bass_synth_device_panel.dart` | Enum: strip, editor |
| Flutter device tab enum | `BassSynthDeviceTab` | `bass_synth_device_panel.dart` | Enum: tone, filter, char |
| Flutter accent color | `bassSynthAccent` | `device_strip_theme.dart` | `Color(0xFF4ADE80)` — neon green |

## Parameter canonical names (C++ parameter IDs and JSON field names)

| Parameter ID | `BassSynthInstance` field | Type | Range | Default | Section |
|-------------|--------------------------|------|-------|---------|---------|
| `bassOscShape` | `oscShape` | float | [0, 1] | 0.5 | TONE |
| `bassSubMix` | `subMix` | float | [0, 1] | 0.5 | TONE |
| `bassSubOctave` | `subOctave` | int | {0,1,2} | 0 | TONE |
| `bassNoise` | `noise` | float | [0, 1] | 0.0 | TONE |
| `bassFilterCutoff` | `filterCutoff` | float | [0, 1] | 0.85 | FILTER |
| `bassFilterResonance` | `filterResonance` | float | [0, 1] | 0.25 | FILTER |
| `bassFilterEnvAmount` | `filterEnvAmount` | float | [0, 1] | 0.6 | FILTER |
| `bassFilterDecay` | `filterDecay` | float | [0, 1] | 0.4 | FILTER |
| `bassAmpAttack` | `ampAttack` | float | [0, 1] | 0.02 | TONE |
| `bassAmpSustain` | `ampSustain` | float | [0, 1] | 0.8 | TONE |
| `bassAmpRelease` | `ampRelease` | float | [0, 1] | 0.35 | TONE |
| `bassDrive` | `drive` | float | [0, 1] | 0.0 | CHAR |
| `bassSquash` | `squash` | float | [0, 1] | 0.0 | CHAR |
| `bassGlide` | `glideMs` | float | [0, 1] | 0.0 | CHAR |
| `bassOctave` | `octave` | int | {0,1,2,3,4} | 2 | TONE |
| `bassVelocitySense` | `velocitySense` | float | [0, 1] | 1.0 | CHAR |

## DeviceState fields (new)

| Field name | Type | Default | Maps to BassSynthInstance |
|-----------|------|---------|--------------------------|
| `bassOscShape` | float | 0.5 | `oscShape` |
| `bassSubMix` | float | 0.5 | `subMix` |
| `bassSubOctave` | int | 0 | `subOctave` |
| `bassNoise` | float | 0.0 | `noise` |
| `bassFilterResonance` | float | 0.25 | `filterResonance` |
| `bassDrive` | float | 0.0 | `drive` |
| `bassSquash` | float | 0.0 | `squash` |
| `bassOctave` | int | 2 | `octave` |
| `bassVelocitySense` | float | 1.0 | `velocitySense` |

Reused DeviceState fields: `gain`, `filterCutoff`, `filterEnvAmount`, `filterDecay`, `attack`, `sustain`, `release`, `glideMs`