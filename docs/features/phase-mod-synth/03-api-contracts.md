# API Contracts: Phase Modulation Synth Device

## 1. DeviceTypeIds.hpp

```cpp
inline constexpr const char* kPhaseModSynth = "phase_mod_synth";
```

## 2. PhaseModSynthDeviceType (implements IDeviceType)

### typeId()
- Returns: `device_types::kPhaseModSynth`

### createDefault(const std::string& deviceId)

Creates a `DeviceSlot` with `PhaseModSynthInstance` initialized to electric-piano-like defaults:

| Field | Default | Rationale |
|-------|---------|-----------|
| `op[0].ratio` | 0.0625 (ratio=1) | Carrier at fundamental |
| `op[0].fine` | 0.5 (0¢) | No detune |
| `op[0].level` | 0.8 | Strong carrier |
| `op[0].wave` | 0.0 (sine) | Pure sine |
| `op[0].attack` | 0.01 | Quick attack |
| `op[0].decay` | 0.3 | Medium decay |
| `op[0].sustain` | 0.8 | High sustain |
| `op[0].release` | 0.4 | Medium release |
| `op[0].velocitySense` | 1.0 | Full velocity |
| `op[0].keyTrack` | 0.0 | No key scaling |
| `op[1].ratio` | 0.4375 (ratio=5) | Modulator at ratio 5 |
| `op[1].level` | 0.4 | Moderate mod depth |
| `op[2].ratio` | 0.75 (ratio=3) | Modulator at ratio 3 |
| `op[2].level` | 0.0 | Off by default |
| `op[3].ratio` | 0.375 (ratio=2) | Modulator at ratio 2 |
| `op[3].level` | 0.0 | Off by default |
| `algoIndex` | 0 | Stack routing |
| `feedback` | 0.0 | No feedback |
| `filterCutoff` | 0.85 | Fairly open |
| `filterQ` | 0.25 | Moderate |
| `ampAttack` | 0.01 | Fast |
| `ampSustain` | 0.75 | High sustain |
| `lfoRate` | 0.2 | Slow LFO |
| `lfoShape` | 0.0 | Sine LFO |
| `lfoAmount` | 0.0 | Off by default |
| `lfoDest` | 0 | Off |

### setParameter(DeviceSlot& slot, std::string_view parameterId, float value)

Maps parameter ID to `PhaseModSynthInstance` field. Operator params use pattern `pmOp{1-4}{ParamName}`:

| parameterId | Clamp rule | Storage field |
|-------------|-----------|---------------|
| `gain` | [0, 1] | `slot.gain` |
| `pan` | [0, 1] | `slot.pan` (handled by device_strip::setStripParameter, NOT stored as pmPan) |
| `bypass` | ≥0.5 ⇒ true | `slot.bypassed` |
| `pmOp1Ratio` → `pmOp4Ratio` | discrete {0..7} via lround | `instance.op[i].ratio` |
| `pmOp1Fine` → `pmOp4Fine` | [0, 1] | `instance.op[i].fine` |
| `pmOp1Level` → `pmOp4Level` | [0, 1] | `instance.op[i].level` |
| `pmOp1Wave` → `pmOp4Wave` | [0, 1] | `instance.op[i].wave` |
| `pmOp1Attack` → `pmOp4Attack` | [0, 1] | `instance.op[i].attack` |
| `pmOp1Decay` → `pmOp4Decay` | [0, 1] | `instance.op[i].decay` |
| `pmOp1Sustain` → `pmOp4Sustain` | [0, 1] | `instance.op[i].sustain` |
| `pmOp1Release` → `pmOp4Release` | [0, 1] | `instance.op[i].release` |
| `pmOp1VelSense` → `pmOp4VelSense` | [0, 1] | `instance.op[i].velocitySense` |
| `pmOp1KeyTrack` → `pmOp4KeyTrack` | [0, 1] | `instance.op[i].keyTrack` |
| `pmAlgoIndex` | {0..7} lround | `instance.algoIndex` |
| `pmFeedback` | [0, 1] | `instance.feedback` |
| `pmUnisonVoices` | [0, 1] | `instance.unisonVoices` |
| `pmUnisonDetune` | [0, 1] | `instance.unisonDetune` |
| `pmGlide` | [0, 1] | `instance.glideMs` |
| `pmMono` | ≥0.5 ⇒ 1 | `instance.synthMono` |
| `pmLegato` | ≥0.5 ⇒ 1 | `instance.synthLegato` |
| `pmMasterVol` | [0, 1] | `instance.masterVol` |
| `pmLfoRate` | [0, 1] | `instance.lfoRate` |
| `pmLfoShape` | {0..4} lround | `instance.lfoShape` |
| `pmLfoAmount` | [0, 1] | `instance.lfoAmount` |
| `pmLfoDest` | {0..4} lround | `instance.lfoDest` |
| `pmVibratoDepth` | [0, 1] | `instance.vibratoDepth` |
| `pmVibratoRate` | [0, 1] | `instance.vibratoRate` |
| `filterCutoff` | [0, 1] | `instance.filterCutoff` |
| `filterQ` | [0, 1] | `instance.filterQ` |
| `filterMode` | {0..5} lround | `instance.filterMode` |
| `filterEnvAmount` | [0, 1] | `instance.filterEnvAmount` |
| `filterAttack` | [0, 1] | `instance.filterAttack` |
| `filterDecay` | [0, 1] | `instance.filterDecay` |
| `filterSustain` | [0, 1] | `instance.filterSustain` |
| `filterRelease` | [0, 1] | `instance.filterRelease` |
| `filterKeyTrack` | [0, 1] | `instance.filterKeyTrack` |
| `attack` | [0, 1] | `instance.ampAttack` |
| `decay` | [0, 1] | `instance.ampDecay` |
| `sustain` | [0, 1] | `instance.ampSustain` |
| `release` | [0, 1] | `instance.ampRelease` |

### setStringParameter()

Supports algorithm selection by name:

| parameterId | values | Behavior |
|-------------|--------|----------|
| `pmAlgo` | `"stack_4"`, `"mod_3_to_1"`, `"mod_3_to_2"`, `"dual_2_to_1"`, `"chain_4"`, `"pair_1_to_2"`, `"one_to_all"`, `"all_mod_fb"` | Maps name to algoIndex {0..7}, returns true |
| anything else | — | Returns false |

```cpp
bool setStringParameter(DeviceSlot& slot, std::string_view parameterId,
                         const std::string& value, const PlaybackBuildContext&) const {
    if (parameterId == "pmAlgo") {
        int algoIdx = -1;
        if (value == "stack_4") algoIdx = 0;
        else if (value == "mod_3_to_1") algoIdx = 1;
        else if (value == "mod_3_to_2") algoIdx = 2;
        else if (value == "dual_2_to_1") algoIdx = 3;
        else if (value == "chain_4") algoIdx = 4;
        else if (value == "pair_1_to_2") algoIdx = 5;
        else if (value == "one_to_all") algoIdx = 6;
        else if (value == "all_mod_fb") algoIdx = 7;

        if (algoIdx >= 0) {
            auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
            inst.algoIndex = algoIdx;
            return true;
        }
    }
    return false;
}
```

### modulatableParams()

Returns:
```
{"gain", "pmFeedback", "pmLfoRate", "pmLfoAmount", "pmVibratoDepth", "pmVibratoRate",
 "filterCutoff", "filterQ", "filterEnvAmount", "filterAttack", "filterDecay",
 "attack", "decay", "sustain", "release",
 "pmOp1Level", "pmOp2Level", "pmOp3Level", "pmOp4Level",
 "pmOp1Fine", "pmOp2Fine", "pmOp3Fine", "pmOp4Fine",
 "pmMasterVol"}
```

### buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out)

```cpp
void buildPlaybackNode(...) {
    const auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
    auto params = inst.toPlaybackParams();
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::PhaseModSynth;
    out.params = params;  // PhaseModSynthParams in DeviceVariantParams
}
```

### buildLiveInstrument(const DeviceSlot& slot, const PlaybackBuildContext&, LiveInstrumentSnapshot& out)

```cpp
bool buildLiveInstrument(...) {
    const auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::PhaseModSynth;
    out.gain = slot.gain;
    out.phaseMod = inst.toPlaybackParams();
    out.phaseMod.gain = slot.gain;
    return true;
}
```

### slotToVar() / varToSlot()

Standard `juce::DynamicObject` serialization. All PM-specific fields prefixed with `pm`.

## 3. PhaseModSynthInstance::toPlaybackParams()

```cpp
PhaseModSynthParams toPlaybackParams() const {
    PhaseModSynthParams p;
    p.masterVol = masterVol;
    p.algoIndex = algoIndex;
    p.feedback = feedback;
    for (int i = 0; i < 4; ++i) {
        p.operators[i].ratio = ratioNormToValue(op[i].ratio);
        p.operators[i].fine = fineNormToCents(op[i].fine);
        p.operators[i].level = op[i].level;
        p.operators[i].wave = op[i].wave;
        p.operators[i].attack = op[i].attack;
        p.operators[i].decay = op[i].decay;
        p.operators[i].sustain = op[i].sustain;
        p.operators[i].release = op[i].release;
        p.operators[i].velocitySense = op[i].velocitySense;
        p.operators[i].keyTrack = op[i].keyTrack;
    }
    // Filter
    p.filterCutoff = filterCutoff;
    p.filterQ = filterQ;
    p.filterMode = static_cast<int>(filterMode);
    p.filterEnvAmount = filterEnvAmount;
    p.filterAttack = filterAttack;
    p.filterDecay = filterDecay;
    p.filterSustain = filterSustain;
    p.filterRelease = filterRelease;
    p.filterKeyTrack = filterKeyTrack;
    // Amp
    p.ampAttack = ampAttack;
    p.ampDecay = ampDecay;
    p.ampSustain = ampSustain;
    p.ampRelease = ampRelease;
    // Global
    p.glideMs = glideMs;
    p.velocitySensitivity = velocitySensitivity;
    p.unisonVoices = unisonVoices;
    p.unisonDetune = unisonDetune;
    p.synthMono = synthMono;
    p.synthLegato = synthLegato;
    // LFO
    p.lfoRate = lfoRate;
    p.lfoShape = lfoShape;
    p.lfoAmount = lfoAmount;
    p.lfoDest = lfoDest;
    p.vibratoDepth = vibratoDepth;
    p.vibratoRate = vibratoRate;
    return p;
}
```

## 4. PhaseModSynthParam enum (AutomationTypes.hpp)

```cpp
/// Added to ParamKind enum.
enum class PhaseModSynthParam : uint16_t {
    // Operator 1
    Op1Level = 0,
    Op1Fine = 1,
    Op1Attack = 2,
    Op1Decay = 3,
    Op1Sustain = 4,
    Op1Release = 5,
    // Operator 2
    Op2Level = 6,
    Op2Fine = 7,
    Op2Attack = 8,
    Op2Decay = 9,
    Op2Sustain = 10,
    Op2Release = 11,
    // Operator 3
    Op3Level = 12,
    Op3Fine = 13,
    Op3Attack = 14,
    Op3Decay = 15,
    Op3Sustain = 16,
    Op3Release = 17,
    // Operator 4
    Op4Level = 18,
    Op4Fine = 19,
    Op4Attack = 20,
    Op4Decay = 21,
    Op4Sustain = 22,
    Op4Release = 23,
    // Filter
    FilterCutoff = 24,
    FilterQ = 25,
    FilterEnvAmount = 26,
    // Amp
    AmpAttack = 27,
    AmpDecay = 28,
    AmpSustain = 29,
    AmpRelease = 30,
    // Global
    Feedback = 31,
    MasterVol = 32,
    LfoRate = 33,
    LfoAmount = 34,
    VibratoDepth = 35,
};
```

## 5. DeviceNodeKind / LiveInstrumentKind entries

```cpp
enum class DeviceNodeKind : uint8_t {
    // ... existing ...
    PhaseModSynth,    // new — dispatches to mixPhaseModMidiNotesBlock
};

enum class LiveInstrumentKind : uint8_t {
    // ... existing ...
    PhaseModSynth,    // new — handles PhaseModSynth in LivePerformance
};
```

## 6. DeviceVariantParams entry (DeviceChain.hpp)

```cpp
using DeviceVariantParams = std::variant<
    // ... existing ...
    PhaseModSynthParams
>;
```
