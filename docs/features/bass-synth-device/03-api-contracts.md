# API Contracts: Bass Synth Device

## 1. DeviceTypeIds.hpp

```cpp
inline constexpr const char* kBassSynth = "bass_synth";
```

## 2. BassSynthDeviceType (implements IDeviceType)

### typeId()
- Returns: `device_types::kBassSynth`

### createDefault(const std::string& deviceId)

Creates a `DeviceSlot` with `BassSynthInstance` initialized to bass-optimized defaults:

| Field | Default | Rationale |
|-------|---------|-----------|
| `oscShape` | 0.3 | Slightly toward saw (aggressive) |
| `subMix` | 0.5 | Equal mix with main |
| `subOctave` | 0 | One octave down (0 = -1 oct) |
| `noise` | 0.0 | Off by default |
| `filterCutoff` | 0.85 | Fairly open |
| `filterResonance` | 0.25 | Moderate |
| `filterEnvAmount` | 0.6 | Medium envelope sweep |
| `filterDecay` | 0.4 | Medium decay |
| `ampAttack` | 0.02 | Fast attack for bass |
| `ampSustain` | 0.8 | High sustain |
| `ampRelease` | 0.35 | Moderate release |
| `drive` | 0.0 | Off by default |
| `squash` | 0.0 | Off by default |
| `glideMs` | 0.0 | Off by default |
| `octave` | 2 | Middle octave (MIDI compat) |
| `velocitySense` | 1.0 | Full velocity response |

### toSnapshotState(const DeviceSlot& slot)

Serializes `BassSynthInstance` into `DeviceState`. Maps:
- `state.type = device_types::kBassSynth`
- bass-specific fields → `state.bassOscShape`, `state.bassSubMix`, etc.
- Shared fields → `state.filterCutoff`, `state.filterEnvAmount`, `state.filterDecay`, `state.glideMs`, `state.attack`, `state.sustain`, `state.release`, `state.gain`

### slotFromSnapshot(const DeviceState& state)

Deserializes `DeviceState` back to `DeviceSlot` with `BassSynthInstance`.

### setParameter(DeviceSlot& slot, std::string_view parameterId, float value)

Maps parameter ID to `BassSynthInstance` field:

| parameterId | Clamp rule | Storage field |
|-------------|-----------|---------------|
| `gain` | [0, 1] | `slot.gain` |
| `pan` | [0, 1] | `slot.pan` |
| `bypass` | ≥0.5 ⇒ true | `slot.bypassed` |
| `bassOscShape` | [0, 1] | `instance.oscShape` |
| `bassSubMix` | [0, 1] | `instance.subMix` |
| `bassSubOctave` | {0,1,2} (lround) | `instance.subOctave` |
| `bassNoise` | [0, 1] | `instance.noise` |
| `filterCutoff` | [0, 1] | `instance.filterCutoff` |
| `bassFilterResonance` | [0, 1] | `instance.filterResonance` |
| `filterEnvAmount` | [0, 1] | `instance.filterEnvAmount` |
| `filterDecay` | [0, 1] | `instance.filterDecay` |
| `attack` | [0, 1] | `instance.ampAttack` |
| `sustain` | [0, 1] | `instance.ampSustain` |
| `release` | [0, 1] | `instance.ampRelease` |
| `bassDrive` | [0, 1] | `instance.drive` |
| `bassSquash` | [0, 1] | `instance.squash` |
| `glideMs` | [0, 1] | `instance.glideMs` |
| `bassOctave` | {0,1,2,3,4} (lround) | `instance.octave` |
| `bassVelocitySense` | [0, 1] | `instance.velocitySense` |

### setStringParameter()
- Returns `false` (no string params).

### modulatableParams()
Returns:
```
{"gain", "pan", "bassOscShape", "bassSubMix", "bassNoise",
 "filterCutoff", "bassFilterResonance", "filterEnvAmount",
 "filterDecay", "attack", "sustain", "release",
 "bassDrive", "bassSquash", "glideMs", "bassVelocitySense"}
```

### buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out)

Builds a full `SubtractiveSynthParams` from `BassSynthInstance` with hardcoded "best" values for hidden params:

```cpp
void buildPlaybackNode(...) {
    const auto& inst = std::get<BassSynthInstance>(slot.instance);
    auto params = inst.toPlaybackParams();  // maps 16 → 50 params
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::BassSynth;
    out.params = params;  // SubtractiveSynthParams in DeviceVariantParams
}
```

### buildLiveInstrument(const DeviceSlot& slot, const PlaybackBuildContext&, LiveInstrumentSnapshot& out)

```cpp
bool buildLiveInstrument(...) {
    const auto& inst = std::get<BassSynthInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::BassSynth;
    out.gain = slot.gain;
    out.subtractive = inst.toPlaybackParams();
    out.subtractive.gain = slot.gain;
    return true;
}
```

## 3. BassSynthInstance::toPlaybackParams()

The critical mapping: 16 curated params → full `SubtractiveSynthParams` (50 params).

```cpp
SubtractiveSynthParams toPlaybackParams() const {
    SubtractiveSynthParams p;
    p.gain = 1.0f;                  // overridden by slot gain
    // --- Osc 1 (main morph oscillator) ---
    p.osc1Shape = oscShape;
    p.osc1Octave = 0.5f;            // neutral — octave uses global
    p.osc1Semi = 0.0f;              // no fine tuning
    p.osc1Detune = 0.5f;            // center detune
    p.osc1Sync = 0.0f;              // no hard sync
    // --- Osc 2 (sub oscillator — sine wave one octave down) ---
    p.osc2Shape = 0.0f;             // force sine
    const float subOctOffsets[] = {-1.0f, -2.0f, -3.0f}; // -1,-2,-3 oct for subOctave 0,1,2
    const float subOctNorm = (subOctOffsets[subOctave] + 4.0f) / 8.0f; // map -3..+4 → 0..1
    p.osc2Octave = std::clamp(subOctNorm, 0.0f, 1.0f);
    p.osc2Semi = 0.0f;
    p.osc2Detune = 0.5f;            // no detune on sub
    p.osc2Sync = 0.0f;
    // --- Osc mix ---
    p.oscMix = subMix;              // subMix controls osc2 level in mix
    p.oscMixMode = 0;               // always Mix mode
    p.noiseLevel = noise;
    // --- Filter (always low-pass 12dB) ---
    p.filterMode = 0;               // LP 12
    p.filterCutoff = filterCutoff;
    p.filterQ = filterResonance;
    p.filterKeyTrack = 0.67f;       // 67% key-track by default
    p.filterEnvAmount = filterEnvAmount;
    p.filterAttack = 0.0f;          // instant attack
    p.filterDecay = filterDecay;
    p.filterSustain = 0.0f;         // ADR envelope — no sustain
    p.filterRelease = 0.0f;
    p.filterDrive = drive;           // filter drive from bassDrive
    p.filterFm = 0.0f;
    p.filterShaper = 0.0f;          // off — drive does the job
    p.filterShaperMode = 1;         // Soft
    // --- Amp ---
    p.ampAttack = ampAttack;
    p.ampDecay = 0.0f;              // not exposed — instant to sustain
    p.ampSustain = ampSustain;
    p.ampRelease = ampRelease;
    // --- Performance ---
    p.glideMs = glideMs;
    p.velocitySensitivity = velocitySense;
    // --- Global ---
    const float octNormValues[5] = {0.0f, 0.125f, 0.25f, 0.375f, 0.5f}; // -4,-3,-2,-1,0 semitones
    p.globalPitch = octNormValues[octave];
    p.synthLegato = 1.0f;           // always legato
    p.synthMono = 1.0f;             // always mono
    // --- Pre-processing (hardcoded to minimal) ---
    p.preHpCutoff = 0.0f;
    p.preHpRes = 0.2f;
    p.preDrive = drive * 0.5f;      // half to pre, half to filter
    // --- Feedback ---
    p.mixFeedback = squash;         // mixFeedback = squash amount
    // --- Fixed / unused ---
    p.unisonVoices = 0.35f;         // ~2 voices unison (1 + 0.35*3 = 2)
    p.unisonDetune = 0.15f;         // light detune
    return p;
}
```

## 4. BassSynthInstance struct

```cpp
struct BassSynthInstance {
    float gain = 1.0f;
    // TONE section
    float oscShape = 0.3f;          // 0=sine, 1=pulse morph
    float subMix = 0.5f;            // 0=only osc1, 1=only sub
    int subOctave = 0;              // 0=-1oct, 1=-2oct, 2=-3oct
    float noise = 0.0f;
    float ampAttack = 0.02f;
    float ampSustain = 0.8f;
    float ampRelease = 0.35f;
    int octave = 2;                 // 0=-4, 1=-3, 2=-2, 3=-1, 4=0 semitones
    // FILTER section
    float filterCutoff = 0.85f;
    float filterResonance = 0.25f;
    float filterEnvAmount = 0.6f;
    float filterDecay = 0.4f;
    // CHARACTER section
    float drive = 0.0f;
    float squash = 0.0f;            // mixFeedback compression
    float glideMs = 0.0f;
    float velocitySense = 1.0f;

    SubtractiveSynthParams toPlaybackParams() const;  // see above
};
```

## 5. Automatable parameter enums (AutomationTypes.hpp)

```cpp
/// Added to ParamKind enum.
enum class BassSynthParam : uint16_t {
    FilterCutoff = 0,
    FilterResonance = 1,
    FilterEnvAmount = 2,
    AmpAttack = 3,
    AmpSustain = 4,
    AmpRelease = 5,
    OscShape = 6,
    SubMix = 7,
    Noise = 8,
    Drive = 9,
    Squash = 10,
    GlideMs = 11,
    VelocitySense = 12,
};
```

## 6. DeviceNodeKind / LiveInstrumentKind entries

```cpp
enum class DeviceNodeKind : uint8_t {
    // ... existing ...
    BassSynth,    // new — dispatches to mixSubtractiveMidiNotesBlock
};

enum class LiveInstrumentKind : uint8_t {
    // ... existing ...
    BassSynth,    // new — handles like SubtractiveSynth in LivePerformance
};
```