# Canonical Vocabulary: Phase Modulation Synth Device

## Binding table

| Concept | Canonical name | Type/file | Notes |
|---------|---------------|-----------|-------|
| Device type ID string | `kPhaseModSynth = "phase_mod_synth"` | `DeviceTypeIds.hpp` | `inline constexpr const char*` |
| Device type class | `PhaseModSynthDeviceType` | `PhaseModSynthDeviceType.hpp` | Inherits `IDeviceType` |
| Device instance struct | `PhaseModSynthInstance` | `PhaseModSynthInstance.hpp` | Holds all PM synth params |
| Instance variant entry | `PhaseModSynthInstance` | `DeviceSlot.hpp` | Added to `DeviceInstance` `std::variant` |
| Audio-thread params struct | `PhaseModSynthParams` | `PhaseModSynth.hpp` | Flat struct — no floats/pointers only |
| Device node kind enum | `DeviceNodeKind::PhaseModSynth` | `DeviceChain.hpp` | Added to `DeviceNodeKind` enum |
| Live instrument kind | `LiveInstrumentKind::PhaseModSynth` | `LivePerformance.hpp` | Added to `LiveInstrumentKind` enum |
| Device variant params entry | `PhaseModSynthParams` | `DeviceChain.hpp` | Added to `DeviceVariantParams` variant |
| Param kind (automation) | `ParamKind::PhaseModSynth` | `AutomationTypes.hpp` | New enum entry |
| PM param enum | `PhaseModSynthParam` | `AutomationTypes.hpp` | New per-device param enum |
| DSP engine header | `PhaseModSynth` | `audioapp/PhaseModSynth.hpp` | New DSP engine |
| DSP engine impl | — | `engine_juce/src/PhaseModSynth.cpp` | New DSP engine implementation |
| Flutter strip widget | `PhaseModSynthDeviceStrip` | `phase_mod_synth_device_strip.dart` | Thin wrapper |
| Flutter panel widget | `PhaseModSynthDevicePanel` | `phase_mod_synth_device_panel.dart` | Full editor with 4 tabs |
| Flutter editor screen | `PhaseModSynthEditorScreen` | `phase_mod_synth_editor_screen.dart` | Fullscreen editor |
| Flutter panel density | `PhaseModSynthPanelDensity` | `phase_mod_synth_device_panel.dart` | Enum: strip, editor |
| Flutter device tab enum | `PhaseModSynthDeviceTab` | `phase_mod_synth_device_panel.dart` | Enum: algo, op, mod, tone |
| Flutter presets file | — | `phase_mod_synth_presets.dart` | 16 factory presets |
| Flutter accent color | `phaseModSynthAccent` | `device_strip_theme.dart` | `Color(0xFFFF6B35)` — vibrant orange |
| Operator index | N/A (0-based int) | — | 0=Op1, 1=Op2, 2=Op3, 3=Op4 |
| Algorithm index | N/A (0-based int) | — | 0-7, stored in `algoIndex` |
| Operator | — | instance struct | One of 4 PM oscillators |
| Algorithm | — | instance struct | Routing matrix index |
| Feedback | — | — | Self-modulation of op 1 |
| Carrier | — | — | Operator routed to output mix |
| Modulator | — | — | Operator routed to another op's phase |
| LFO | — | — | Global modulation oscillator |

## Parameter canonical names (C++ parameter IDs and JSON field names)

### Operator parameters (×4 operators)

| Parameter ID | Instance field | Type | Range | Default | Notes |
|-------------|---------------|------|-------|---------|-------|
| `pmOp1Ratio` | `op[0].ratio` | float | [0, 1] → 0.5,1,1.5,2,3,4,5,6,8 | 0.0625 (ratio=1) | Coarse freq ratio |
| `pmOp1Fine` | `op[0].fine` | float | [0, 1] → -50..+50 cents | 0.5 | Fine detune cents |
| `pmOp1Level` | `op[0].level` | float | [0, 1] | 0.8 | Operator output level |
| `pmOp1Wave` | `op[0].wave` | float | [0, 1] → sine/tri/saw/square/noise | 0.0 | Waveform shape morph |
| `pmOp1Attack` | `op[0].attack` | float | [0, 1] | 0.01 | ADSR attack |
| `pmOp1Decay` | `op[0].decay` | float | [0, 1] | 0.3 | ADSR decay |
| `pmOp1Sustain` | `op[0].sustain` | float | [0, 1] | 0.8 | ADSR sustain |
| `pmOp1Release` | `op[0].release` | float | [0, 1] | 0.4 | ADSR release |
| `pmOp1VelSense` | `op[0].velocitySense` | float | [0, 1] | 1.0 | Velocity sensitivity for this op |
| `pmOp1KeyTrack` | `op[0].keyTrack` | float | [0, 1] | 0.0 | Key scaling (optional) |

Repeat for Op2 (pmOp2*), Op3 (pmOp3*), Op4 (pmOp4*).

### Global / algorithm parameters

| Parameter ID | Instance field | Type | Range | Default | Notes |
|-------------|---------------|------|-------|---------|-------|
| `pmAlgoIndex` | `algoIndex` | int | {0..7} | 0 | Algorithm routing |
| `pmFeedback` | `feedback` | float | [0, 1] | 0.0 | Operator 1 self-feedback |
| `pmUnisonVoices` | `unisonVoices` | float | [0, 1] → 1..4 | 0.0 | Unison count |
| `pmUnisonDetune` | `unisonDetune` | float | [0, 1] | 0.15 | Unison detune spread |
| `pmGlide` | `glideMs` | float | [0, 1] → 0..2000ms | 0.0 | Portamento/glide time |
| `pmMono` | `synthMono` | float | [0, 1] | 0.0 | Mono mode toggle |
| `pmLegato` | `synthLegato` | float | [0, 1] | 0.0 | Legato mode toggle |
| `pmMasterVol` | `masterVol` | float | [0, 1] | 0.85 | Master volume (internal, separate from slot.gain) |
| `pan` | `slot.pan` | float | [0, 1] | 0.5 | Stereo pan (handled by device_strip::setStripParameter, stored in slot.pan) |

### LFO parameters

| Parameter ID | Instance field | Type | Range | Default | Notes |
|-------------|---------------|------|-------|---------|-------|
| `pmLfoRate` | `lfoRate` | float | [0, 1] | 0.2 | Global LFO rate |
| `pmLfoShape` | `lfoShape` | float | [0, 1] → sine/tri/saw/square/s&h | 0.0 | LFO waveform |
| `pmLfoAmount` | `lfoAmount` | float | [0, 1] | 0.0 | LFO modulation amount |
| `pmLfoDest` | `lfoDest` | int | {0..4} | 0 | LFO destination: 0=off, 1=pitch, 2=filter, 3=amp, 4=pmAmount |
| `pmVibratoDepth` | `vibratoDepth` | float | [0, 1] | 0.0 | Vibrato depth |
| `pmVibratoRate` | `vibratoRate` | float | [0, 1] | 0.3 | Vibrato rate |

### Reused DeviceState fields (shared with existing system)

| Parameter ID | Instance field | Type | Range | Default |
|-------------|---------------|------|-------|---------|
| `filterCutoff` | `filterCutoff` | float | [0, 1] | 0.85 |
| `filterQ` | `filterQ` | float | [0, 1] | 0.25 |
| `filterMode` | `filterMode` | int | {0..5} | 0 |
| `filterEnvAmount` | `filterEnvAmount` | float | [0, 1] | 0.5 |
| `filterAttack` | `filterAttack` | float | [0, 1] | 0.05 |
| `filterDecay` | `filterDecay` | float | [0, 1] | 0.35 |
| `filterSustain` | `filterSustain` | float | [0, 1] | 0.4 |
| `filterRelease` | `filterRelease` | float | [0, 1] | 0.45 |
| `filterKeyTrack` | `filterKeyTrack` | float | [0, 1] | 0.0 |
| `attack` | `ampAttack` | float | [0, 1] | 0.01 |
| `decay` | `ampDecay` | float | [0, 1] | 0.3 |
| `sustain` | `ampSustain` | float | [0, 1] | 0.75 |
| `release` | `ampRelease` | float | [0, 1] | 0.35 |
| `gain` | `slot.gain` | float | [0, 1] | 1.0 |

## PhaseModSynthParams (audio-thread struct) — field names

| Field | Type | Maps from instance |
|-------|------|--------------------|
| `gain` | float | slot.gain |
| `operators[4]` | OpParams | instance.op[0..3] |
| `algoIndex` | int | instance.algoIndex |
| `feedback` | float | instance.feedback |
| `filterCutoff` | float | instance.filterCutoff |
| `filterQ` | float | instance.filterQ |
| `filterMode` | int | instance.filterMode |
| `filterEnvAmount` | float | instance.filterEnvAmount |
| `filterAttack` | float | instance.filterAttack |
| `filterDecay` | float | instance.filterDecay |
| `filterSustain` | float | instance.filterSustain |
| `filterRelease` | float | instance.filterRelease |
| `filterKeyTrack` | float | instance.filterKeyTrack |
| `ampAttack` | float | instance.ampAttack |
| `ampDecay` | float | instance.ampDecay |
| `ampSustain` | float | instance.ampSustain |
| `ampRelease` | float | instance.ampRelease |
| `glideMs` | float | instance.glideMs |
| `velocitySensitivity` | float | instance.velocitySensitivity |
| `unisonVoices` | float | instance.unisonVoices |
| `unisonDetune` | float | instance.unisonDetune |
| `synthMono` | float | instance.synthMono |
| `synthLegato` | float | instance.synthLegato |
| `masterVol` | float | instance.masterVol |
| `lfoRate` | float | instance.lfoRate |
| `lfoShape` | float | instance.lfoShape |
| `lfoAmount` | float | instance.lfoAmount |
| `lfoDest` | int | instance.lfoDest |
| `vibratoDepth` | float | instance.vibratoDepth |
| `vibratoRate` | float | instance.vibratoRate |

## Flutter DeviceSnapshot fields (new)

| Field name | Type | Default | JSON key |
|-----------|------|---------|----------|
| `pmOp1Ratio` | double | 0.0625 | `pmOp1Ratio` |
| `pmOp1Fine` | double | 0.5 | `pmOp1Fine` |
| `pmOp1Level` | double | 0.8 | `pmOp1Level` |
| `pmOp1Wave` | double | 0.0 | `pmOp1Wave` |
| `pmOp1Attack` | double | 0.01 | `pmOp1Attack` |
| `pmOp1Decay` | double | 0.3 | `pmOp1Decay` |
| `pmOp1Sustain` | double | 0.8 | `pmOp1Sustain` |
| `pmOp1Release` | double | 0.4 | `pmOp1Release` |
| `pmOp1VelSense` | double | 1.0 | `pmOp1VelSense` |
| `pmOp1KeyTrack` | double | 0.0 | `pmOp1KeyTrack` |
| *Same pattern for Op2, Op3, Op4* | | | |
| `pmAlgoIndex` | int | 0 | `pmAlgoIndex` |
| `pmFeedback` | double | 0.0 | `pmFeedback` |
| `pmUnisonVoices` | double | 0.0 | `pmUnisonVoices` |
| `pmUnisonDetune` | double | 0.15 | `pmUnisonDetune` |
| `pmGlide` | double | 0.0 | `pmGlide` |
| `pmMono` | double | 0.0 | `pmMono` |
| `pmLegato` | double | 0.0 | `pmLegato` |
| `pmMasterVol` | double | 0.85 | `pmMasterVol` |
| `pmLfoRate` | double | 0.2 | `pmLfoRate` |
| `pmLfoShape` | double | 0.0 | `pmLfoShape` |
| `pmLfoAmount` | double | 0.0 | `pmLfoAmount` |
| `pmLfoDest` | int | 0 | `pmLfoDest` |
| `pmVibratoDepth` | double | 0.0 | `pmVibratoDepth` |
| `pmVibratoRate` | double | 0.3 | `pmVibratoRate` |

Reused DeviceSnapshot fields: `gain`, `filterCutoff`, `filterQ`, `filterMode`, `filterEnvAmount`, `filterAttack`, `filterDecay`, `filterSustain`, `filterRelease`, `filterKeyTrack`, `attack`, `decay`, `sustain`, `release`
