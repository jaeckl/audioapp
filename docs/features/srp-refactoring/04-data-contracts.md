# Data Contracts

## 4.1 JSON Data Format (Unchanged)

The `project.json` format inside `.audioapproj` archives is **unchanged** by
this refactoring. Each `deviceToVar` serializer produces exactly the same
key/value pairs as the current inline code.

### Canonical device JSON shape for "simple_oscillator":

```json
{
    "id": "dev_abc123",
    "type": "simple_oscillator",
    "parameters": {
        "bypass": 0.0,
        "gain": 1.0,
        "pan": 0.5,
        "frequency": 440.0
    }
}
```

### Canonical device JSON shape for "subtractive_synth":

```json
{
    "id": "dev_def456",
    "type": "subtractive_synth",
    "parameters": {
        "bypass": 0.0,
        "gain": 1.0,
        "pan": 0.5,
        "attack": 0.01,
        "decay": 0.3,
        "sustain": 0.7,
        "release": 0.4,
        "filterCutoff": 0.75,
        "filterQ": 0.2,
        "filterMode": 0,
        "filterEnvAmount": 0.5,
        "filterAttack": 0.05,
        "filterDecay": 0.35,
        "filterSustain": 0.4,
        "filterRelease": 0.45,
        "osc1Shape": 0.5,
        "osc2Shape": 0.5,
        "osc1Octave": 0.5,
        "osc1Semi": 0.0,
        ...etc
    }
}
```

### All 14 device types maintain their existing JSON shapes.

---

## 4.2 DeviceState Struct (Unchanged in Phase 1)

`DeviceState` remains a single monolithic struct with all ~100 fields. The
per-device serializers read the monolithic struct but only access their own
fields. This is acceptable because `DeviceState` is a control-thread DTO
with no realtime constraints.

**Phase B (future only):** Decompose into discriminated variant:

```cpp
struct OscillatorState { float frequencyHz = 440.0f; };
struct SamplerState {
    std::string sampleId; float attack; float decay; float sustain; float release;
    float filterCutoff; float filterQ; int filterMode;
    // ...
};

struct DeviceState {
    std::string id;
    std::string type;
    float gain = 1.0f;
    float pan = 0.5f;
    bool bypassed = false;
    std::variant<OscillatorState, SamplerState, SubtractiveSynthState,
                 BassSynthState, KickGeneratorState, SnareGeneratorState,
                 ClapGeneratorState, CymbalGeneratorState, CrashGeneratorState,
                 GateState, CompressorState, ExpanderState, LimiterState,
                 TrackGainState> params;
};
```

**This Phase B is NOT required now.**

---

## 4.3 Audio-Thread Params (Unchanged)

`DeviceVariantParams`, `OscillatorParams`, `SubtractiveSynthParams`, etc. are
**unchanged**. They are already clean DSP-only structs. The refactoring does
not modify them.

---

## 4.4 Bridge JSON (Unchanged)

Bridge response formats stay identical:

```json
{"ok": true, "snapshot": {...}}
{"ok": false, "error": "track_not_found"}
{"ok": true, "message": "pong"}
{"ok": true, "playheadBeats": 4.0, "playing": true, "bpm": 120, ...}
```
