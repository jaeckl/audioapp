# Device SRP Refactoring — Architecture Contract

> **STATUS: COMPLETED** — All 3 phases (contract, Phase 2 persistence dispatch, Phase 3 snapshot dispatch) are implemented.
>
> - Phase 1 (contract foundations): `DeviceSlot` variant, `IDeviceType` interface, `DeviceRegistry`
> - Phase 2 (persistence): `trackToVarPersistence`/`trackFromVarPersistence` via registry dispatch — commit `2bcaf6b`
> - Phase 3 (snapshot): `trackToVarSnapshot` via registry dispatch, `DeviceState` eliminated — commit `56eceef` + `4d61807`
>
> All tests pass. No further work needed.

> Refactor device serialization out of `ProjectJson.cpp` into each device type, while preserving thread safety, the audio-thread flat snapshot pattern, and backward compatibility.

---

## A. Canonical Vocabulary

| Concept | Canonical name | Location | Notes |
|---------|----------------|----------|-------|
| Device factory / descriptor | `IDeviceType` | `engine_juce/include/audioapp/devices/IDeviceType.hpp` | One instance per built-in device kind. Control thread only. |
| Typed instance struct | `OscillatorInstance`, `CompressorInstance`, etc. | `engine_juce/include/audioapp/devices/instances/*Instance.hpp` | Per-device POD state. Has `toPlaybackParams()`. |
| Control-thread slot | `DeviceSlot` | `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | `std::variant<DeviceInstance>` + id/gain/pan/bypass. |
| Flat snapshot DTO | `DeviceState` | `engine_juce/include/audioapp/DeviceState.hpp` | Flat union of all device fields. Used for bridge snapshots. |
| Audio-thread playback node | `DeviceNodePlayback` | `engine_juce/include/audioapp/DeviceChain.hpp` | `DeviceNodeKind` + `DeviceVariantParams`. Built on control thread. |
| Device kind enum | `DeviceNodeKind` | `engine_juce/include/audioapp/DeviceChain.hpp` | `uint8_t` enum. Audio-thread dispatch via switch. |
| Device registry | `DeviceRegistry` | `engine_juce/include/audioapp/devices/DeviceRegistry.hpp` | Owns `IDeviceType` instances. `find()`, `findForSlot()`. |
| Type ID constants | `device_types::kOscillator`, etc. | `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp` | `constexpr const char*` values. |
| Strip parameter helpers | `device_strip::setStripParameter` | `engine_juce/include/audioapp/devices/DeviceStripParams.hpp` | Shared gain/pan/bypass logic for all device types. |
| Serialization central | `ProjectJson` | `engine_juce/include/audioapp/ProjectJson.hpp` + `.cpp` | Top-level project ↔ JSON. Will delegate per-device JSON. |
| Per-device JSON serializer | `slotToVar()` | NEW — on `IDeviceType` | Serializes entire `DeviceSlot` to `juce::var`. |
| Per-device JSON deserializer | `varToSlot()` | NEW — on `IDeviceType` | Deserializes `juce::var` to `DeviceSlot`. |
| JSON dispatching function | `deviceSlotToVar()` | NEW — in `ProjectJson.cpp` or new helper | Looks up `IDeviceType*` from registry, delegates. |
| DSP processing function | `addSineBlock()`, `processCompressorStereoBlock()`, etc. | `engine_juce/src/DeviceChain.cpp` and DSP module files | Free functions dispatched via `switch(DeviceNodeKind)`. **Not changed.** |

---

## B. What Stays the Same (Critical Invariants)

| Invariant | Rationale |
|-----------|-----------|
| Audio thread uses `DeviceNodePlayback` + `DeviceNodeKind` switch dispatch. | No virtual calls on audio thread. Deliberate performance decision. |
| `DeviceNodePlayback.params` is `std::variant<OscillatorParams, SamplerParams, ...>`. | Flat POD struct per device kind. No allocations on audio thread. |
| `processDeviceChain()` signature and dispatch logic. | Stable audio-thread contract. Not touched. |
| `DeviceState` flat struct exists for bridge snapshots. | Flutter bridge reads `DeviceState` in snapshot JSON. Changing this would break the bridge contract. |
| `DeviceSlot` variant with id/gain/pan/bypassed/instance. | Control-thread state holder. Unchanged. |
| `DeviceRegistry::createBuiltIn()` and registration pattern. | Factory pattern for device types. Unchanged. |
| `DeviceStripParams` inline helpers. | Shared gain/pan/bypass logic. Unchanged. |
| All existing test file names and test entry points. | Existing tests must continue to compile and pass. |
| JSON project file schema. | Field names, nesting, defaults must be identical for backward compatibility. |

---

## C. What Changes

### C.1 New methods on `IDeviceType`

```cpp
// File: engine_juce/include/audioapp/devices/IDeviceType.hpp

class IDeviceType {
public:
    // ... existing methods unchanged ...

    /// Serialize a DeviceSlot to a juce::var suitable for JSON output.
    /// Must write the same structure as the current deviceToVar():
    ///   { "id": "...", "type": "...", "parameters": { ... }, "meters": { ... } }
    /// Called on the control thread only.
    /// Thread safety: must NOT read or write any mutable global state.
    virtual juce::var slotToVar(const DeviceSlot& slot) const = 0;

    /// Deserialize a juce::var (parsed JSON) to a DeviceSlot.
    /// Must read the same structure as the current deviceFromVar().
    /// Must handle legacy field renames (e.g., osc1Wave -> osc1Shape).
    /// Called on the control thread only.
    virtual DeviceSlot varToSlot(const juce::var& obj) const = 0;
};
```

### C.2 Each device type implements slotToVar/varToSlot

Each `*DeviceType.cpp` implements these methods. The implementation is a direct extraction of the current `deviceToVar`/`deviceFromVar` if-branch for that device type, with two key differences:

1. **Input/output is `DeviceSlot`, not `DeviceState`.** The method constructs the JSON directly from the typed instance struct instead of from the flat `DeviceState` union.
2. **Legacy field support stays in each device's own code.** The `varToSlot` method handles backward-compatible field renames (e.g., `osc1Wave` → `osc1Shape`, `cymbalMetal` → `cymbalColor`) within the device's own implementation.

**JSON output contract** (identical to current format):

```json
{
  "id": "dev-001",
  "type": "compressor",
  "parameters": {
    "gain": 0.8,
    "pan": 0.5,
    "bypass": 0.0,
    "inputGain": 1.0,
    "compThreshold": 0.55,
    "compRatio": 0.5,
    "compAttack": 0.2,
    "compRelease": 0.55,
    "compKnee": 0.25,
    "compMakeup": 0.35
  },
  "meters": {
    "gainReductionDb": 0.0,
    "inputLevel": 0.0
  }
}
```

The `parameters` object includes:
- Strip fields: `gain`, `pan`, `bypass` (handled by each device type)
- Device-specific fields: depending on device type
- `meters` sub-object: only for dynamics devices (gate, compressor, expander, limiter)

### C.3 New dispatch functions

A new namespace or static functions in `ProjectJson.cpp`:

```cpp
// Internal use — called by the refactored deviceToVar/deviceFromVar
// when the DeviceRegistry is available.

juce::var deviceSlotToVar(const DeviceSlot& slot, const DeviceRegistry& registry);
DeviceSlot deviceVarToSlot(const juce::var& obj, const DeviceRegistry& registry);
```

These functions:
1. Look up the `IDeviceType*` via `registry.findForSlot(slot)` or `registry.find(typeStr)`
2. If found, call `type->slotToVar(slot)` or `type->varToSlot(obj)`
3. If not found, return empty/default

### C.4 Refactored `deviceToVar` / `deviceFromVar`

`ProjectJson.cpp`'s `deviceToVar(const DeviceState&)` and `deviceFromVar(const juce::var&)` keep their existing signatures for backward compatibility (used by snapshot-to-bridge path).

They are refactored internally to:

```cpp
juce::var deviceToVar(const DeviceState& device, const DeviceRegistry& registry) {
    // Convert DeviceState -> DeviceSlot via registry.slotFromSnapshot
    // then call deviceSlotToVar(slot, registry)
}

DeviceState deviceFromVar(const juce::var& value, const DeviceRegistry& registry) {
    // Call deviceVarToSlot(value, registry) to get DeviceSlot
    // then convert DeviceSlot -> DeviceState via registry.toSnapshotState
}
```

A **new overload** is added for callers that have access to the registry. The old overload (without registry) is kept for the snapshot bridge path where `DeviceState` is the source of truth.

**Migration path:**
1. Add `slotToVar`/`varToSlot` to `IDeviceType` (new pure virtuals)
2. Implement for each device type, one at a time
3. Add `deviceSlotToVar`/`deviceVarToSlot` dispatching functions
4. Create new overloads of `deviceToVar`/`deviceFromVar` that accept registry
5. Update `ProjectEngine.cpp` persistence paths to use new overloads
6. Remove the giant if/else-if chain from `deviceToVar`/`deviceFromVar`

### C.5 ProjectEngine persistence paths

In `ProjectEngine.cpp`:

**Save path (`getProjectFileJson`):**
```cpp
// Before: builds DeviceState vectors, serializes via deviceToVar(state)
// After: builds DeviceSlot vectors, serializes via deviceSlotToVar(slot, registry_)
```

**Load path (`loadProjectFileJson`):**
```cpp
// Before: deserializes to DeviceState vectors, converts to DeviceSlot via slotFromSnapshot
// After: deserializes directly to DeviceSlot via deviceVarToSlot(obj, registry_)
```

This means `ProjectEngine::buildProjectFileData()` or a new parallel path needs to work with `DeviceSlot` directly instead of going through `DeviceState`. Since `ProjectEngine` already stores `DeviceSlot` internally (in `track.devices`), the save path can traverse the internal `DeviceSlot` list instead of converting to `DeviceState`.

### C.6 Common strip fields in per-device serialization

Each `slotToVar()` implementation must write the common strip fields (`gain`, `pan`, `bypass`) into the `parameters` object, EXCEPT:
- `TrackGainDeviceType` must NOT write `pan` or `bypass` (current behavior: track_gain writes gain but not pan or bypass)
- `bypass` is written as double `1.0` / `0.0` (current behavior)

Each `varToSlot()` must read these from the `parameters` object and apply them to the `DeviceSlot.gain`, `DeviceSlot.pan`, `DeviceSlot.bypassed` fields.

---

## D. File Ownership

| File/path | Owner package | Allowed changes | Forbidden changes |
|-----------|--------------|-----------------|-------------------|
| `engine_juce/include/audioapp/devices/IDeviceType.hpp` | Package 0 (prerequisite) | Add `slotToVar`/`varToSlot` pure virtuals | Remove or change existing methods. Change `#include`s that break compilation. |
| `engine_juce/include/audioapp/ProjectJson.hpp` | Package 0 | Add `deviceSlotToVar`/`deviceVarToSlot` declarations. Add registry-aware overloads. | Remove existing declarations. Change snapshotToJson signature. |
| `engine_juce/src/ProjectJson.cpp` | Package 0 (then each device migrates) | Add dispatch functions. Remove if/else-if chain per device. | Break backward JSON compat. Change snapshot path. |
| `engine_juce/src/devices/*DeviceType.cpp` (each) | Package 1-14 (one per device) | Implement `slotToVar`/`varToSlot`. | Change existing `toSnapshotState`/`slotFromSnapshot`/`buildPlaybackNode` signatures or behavior. |
| `engine_juce/include/audioapp/devices/instances/*Instance.hpp` | NONE — read-only | None | No changes needed. |
| `engine_juce/include/audioapp/DeviceState.hpp` | NONE — read-only | None | No changes needed. DeviceState stays unchanged throughout. |
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | NONE — read-only | None | No changes needed. |
| `engine_juce/include/audioapp/DeviceChain.hpp` | NONE — read-only | None | No changes needed. Audio thread contract stays. |
| `engine_juce/src/DeviceChain.cpp` | NONE — read-only | None | No changes needed. |
| `engine_juce/src/ProjectEngine.cpp` | Package 0 (integration) | Update save/load paths to use `DeviceSlot`-based serialization with registry dispatch. | Remove `DeviceSlot` storage. Change bridge snapshot format. |
| `engine_juce/include/audioapp/ProjectEngine.hpp` | Package 0 | Minor: expose `DeviceRegistry&` getter if needed. | Change public API. |
| `engine_juce/CMakeLists.txt` | Package 0 | None needed (existing files only). | Add new source files. |
| `engine_juce/tests/project_serialization_test.cpp` | Test migration (parallel to device packages) | Keep existing tests. Optionally add round-trip per-type tests. | Remove existing assertions. |

---

## E. Vertical Work Packages

### Package 0 (Prerequisite): Interface + Dispatch + Integration

**Behavior:** Add `slotToVar`/`varToSlot` to interface, add dispatch infrastructure, keep old if/else-if as fallback.

**Files changed:**
- `engine_juce/include/audioapp/devices/IDeviceType.hpp` — add two pure virtuals
- `engine_juce/include/audioapp/ProjectJson.hpp` — add `deviceSlotToVar`/`deviceVarToSlot` declarations, registry-aware overloads
- `engine_juce/src/ProjectJson.cpp` — add dispatch functions with fallback to old chain
- `engine_juce/src/ProjectEngine.cpp` — update persistence paths

**Canonical names used:** `IDeviceType`, `DeviceSlot`, `DeviceRegistry`, `DeviceState`

**API contracts used:** New `slotToVar`/`varToSlot` on `IDeviceType`. New `deviceSlotToVar`/`deviceVarToSlot` free functions.

**Dependencies:** None (this is the foundation).

**Acceptance criteria:**
- All existing tests compile and pass
- Round-trip save/load produces identical JSON (verified by `project_serialization_test.cpp`)
- New `slotToVar`/`varToSlot` are declared on `IDeviceType` with default implementation that asserts (prevents link errors for unimplemented devices)

**Parallelization:** Sequential — must be done first.

---

### Package 1: TrackGainDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `TrackGainDeviceType`. Track gain is the simplest device (only gain parameter, no pan, no bypass in JSON).

**Files changed:**
- `engine_juce/src/devices/TrackGainDeviceType.cpp`

**Field mapping (from `TrackGainInstance`):**
- `parameters.gain` ← `slot.gain` (identical behavior: track_gain writes gain but not pan or bypass)

**JSON output:**
```json
{ "id": "...", "type": "track_gain", "parameters": { "gain": 1.0 } }
```

**Parallelization:** Parallel-safe with packages 2-14 (all device packages are independent).

**Acceptance criteria:**
- `slotToVar`/`varToSlot` round-trip produce same slot contents
- JSON output matches existing `deviceToVar` for a track_gain device
- `deviceToVar(deviceState)` with old fallback still produces identical output

---

### Package 2: OscillatorDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `OscillatorDeviceType`. Simple device (one field: `frequencyHz`).

**Files changed:**
- `engine_juce/src/devices/OscillatorDeviceType.cpp`

**Field mapping:**
- `parameters.frequency` ← `OscillatorInstance.frequencyHz`

**Legacy support:** None needed (no renames for oscillator).

**Parallelization:** Parallel-safe with other device packages.

---

### Package 3: GateDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `GateDeviceType`. Includes dynamics meter fields.

**Files changed:**
- `engine_juce/src/devices/GateDeviceType.cpp`

**Fields:** `inputGain`, `gateThreshold`, `gateAttack`, `gateRelease`, `gateHold`, `gateRange`, strip fields.
**Meters:** `gainReductionDb`, `inputLevel`.

**Parallelization:** Parallel-safe.

---

### Package 4: CompressorDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `CompressorDeviceType`.

**Files changed:**
- `engine_juce/src/devices/CompressorDeviceType.cpp`

**Fields:** `inputGain`, `compThreshold`, `compRatio`, `compAttack`, `compRelease`, `compKnee`, `compMakeup`, strip fields.
**Meters:** `gainReductionDb`, `inputLevel`.

**Parallelization:** Parallel-safe.

---

### Package 5: ExpanderDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `ExpanderDeviceType`.

**Files changed:**
- `engine_juce/src/devices/ExpanderDeviceType.cpp`

**Fields:** `inputGain`, `expandThreshold`, `expandRatio`, `expandAttack`, `expandRelease`, `expandRange`, strip fields.
**Meters:** `gainReductionDb`, `inputLevel`.

**Parallelization:** Parallel-safe.

---

### Package 6: LimiterDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `LimiterDeviceType`.

**Files changed:**
- `engine_juce/src/devices/LimiterDeviceType.cpp`

**Fields:** `inputGain`, `limitCeiling`, `limitAttack`, `limitRelease`, `limitKnee`, `limitDrive`, `limitMakeup`, strip fields.
**Meters:** `gainReductionDb`, `inputLevel`.

**Parallelization:** Parallel-safe.

---

### Package 7: SamplerDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `SamplerDeviceType`.

**Files changed:**
- `engine_juce/src/devices/SamplerDeviceType.cpp`

**Fields:** `sampleId`, `attack`, `decay`, `sustain`, `release`, `filterCutoff`, `filterQ`, `filterMode`, `trimStartSec`, `trimEndSec`, `regionStartSec`, `regionEndSec`, `rootPitch`, `rootFineTune`, `playbackMode`, `pan`, `gain`, `bypass`.

**Parallelization:** Parallel-safe.

---

### Package 8: SubtractiveSynthDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `SubtractiveSynthDeviceType`.

**Files changed:**
- `engine_juce/src/devices/SubtractiveSynthDeviceType.cpp`

**Fields:** 25+ parameters (osc1Shape through synthMono), plus strip fields.

**Legacy support:** `osc1Wave` → `osc1Shape`, `osc2Wave` → `osc2Shape`, `osc1Level`/`osc2Level` → `oscMix` (computation).

**Parallelization:** Parallel-safe.

---

### Package 9: BassSynthDeviceType serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for `BassSynthDeviceType`.

**Files changed:**
- `engine_juce/src/devices/BassSynthDeviceType.cpp`

**Fields:** `bassOscShape`, `bassSubMix`, `bassSubOctave`, `bassNoise`, `bassFilterResonance`, `bassDrive`, `bassSquash`, `bassOctave`, `bassVelocitySense`, `attack`, `sustain`, `release`, `filterCutoff`, `filterEnvAmount`, `filterDecay`, `glideMs`, plus strip fields.

**Parallelization:** Parallel-safe.

---

### Package 10-14: Drum generator device serialization

**Behavior:** Implement `slotToVar`/`varToSlot` for each drum generator device kind.

**Files changed (one per device):**
- `engine_juce/src/devices/KickGeneratorDeviceType.cpp`
- `engine_juce/src/devices/SnareGeneratorDeviceType.cpp`
- `engine_juce/src/devices/ClapGeneratorDeviceType.cpp`
- `engine_juce/src/devices/CymbalGeneratorDeviceType.cpp`
- `engine_juce/src/devices/CrashGeneratorDeviceType.cpp`

**Legacy support:**
- Cymbal: `cymbalMetal`/`cymbalBrightness` → `cymbalColor`
- Crash: `crashWash`/`crashBright` → `crashColor`

**Parallelization:** All five are parallel-safe.

---

### Package 15 (Integration): Remove fallback chain

**Behavior:** After all device types have `slotToVar`/`varToSlot` implemented, remove the giant if/else-if chain from `deviceToVar`/`deviceFromVar` in `ProjectJson.cpp`. The dispatch functions become the only path.

**Files changed:**
- `engine_juce/src/ProjectJson.cpp` — remove old deviceToVar/deviceFromVar implementations, keep only registry-dispatching versions
- `engine_juce/src/ProjectEngine.cpp` — verify persistence uses registry-dispatching path only

**Acceptance criteria:**
- All tests pass with the old code removed
- No `type == "..."` string comparisons remain in `ProjectJson.cpp`

---

## F. Parallelism and Dependencies

```
Package 0 (prerequisite)
  │
  ├──→ Package 1  (TrackGain)   ── parallel ──┐
  ├──→ Package 2  (Oscillator)  ── parallel ──┤
  ├──→ Package 3  (Gate)        ── parallel ──┤
  ├──→ Package 4  (Compressor)  ── parallel ──┤
  ├──→ Package 5  (Expander)    ── parallel ──┤
  ├──→ Package 6  (Limiter)     ── parallel ──┤
  ├──→ Package 7  (Sampler)     ── parallel ──┤
  ├──→ Package 8  (Subtractive) ── parallel ──┤
  ├──→ Package 9  (BassSynth)   ── parallel ──┤
  ├──→ Package 10 (KickGen)     ── parallel ──┤
  ├──→ Package 11 (SnareGen)    ── parallel ──┤
  ├──→ Package 12 (ClapGen)     ── parallel ──┤
  ├──→ Package 13 (CymbalGen)   ── parallel ──┤
  └──→ Package 14 (CrashGen)    ── parallel ──┤
                                              │
                                              └──→ Package 15 (Integration)
```

- **Package 0**: Must be done first (interface + dispatch + migration pattern)
- **Packages 1–14**: All can run in parallel AFTER Package 0
- **Package 15**: Must be done after ALL of 1–14 are done

---

## G. API/Data Contracts

### G.1 New `IDeviceType` methods

```cpp
// engine_juce/include/audioapp/devices/IDeviceType.hpp

/// Serialize the full DeviceSlot (including strip fields) to juce::var.
/// Produces: { "id", "type", "parameters": { strip + device fields }, "meters"? }
/// Parameters mode: "parameters" key is mandatory.
/// Strip fields in "parameters": "gain", "pan", "bypass" (as double, 1.0/0.0 for bypass).
/// Meters ("gainReductionDb", "inputLevel") written as "meters" sub-object for dynamics devices.
/// Called from control thread only. Must not allocate (juce::DynamicObject handles allocation).
virtual juce::var slotToVar(const DeviceSlot& slot) const = 0;

/// Deserialize a juce::var to a DeviceSlot.
/// Reads "id", "type" from top level.
/// Reads "gain", "pan", "bypass" from "parameters" -> slot fields.
/// Reads device-specific fields from "parameters" -> typed instance.
/// Reads "meters" if present.
/// On unrecognized fields: silently ignore (forward compat).
/// Called from control thread only.
virtual DeviceSlot varToSlot(const juce::var& obj) const = 0;
```

### G.2 New dispatch functions

```cpp
// engine_juce/include/audioapp/ProjectJson.hpp

/// Serialize a DeviceSlot to JSON via its registered IDeviceType.
/// Returns empty juce::var (null) if type is not registered.
juce::var deviceSlotToVar(const DeviceSlot& slot, const DeviceRegistry& registry);

/// Deserialize a juce::var to a DeviceSlot via its registered IDeviceType.
/// Returns default DeviceSlot with empty id if type is unknown or unregistered.
DeviceSlot deviceVarToSlot(const juce::var& obj, const DeviceRegistry& registry);

/// Registry-aware overloads of existing functions.
/// These replace the if/else-if chain with registry dispatch.
/// The old DeviceState-only overloads remain for the snapshot bridge path.
juce::var deviceToVar(const DeviceState& device, const DeviceRegistry& registry);
DeviceState deviceFromVar(const juce::var& value, const DeviceRegistry& registry);
```

### G.3 Error handling

| Scenario | Behavior |
|----------|----------|
| Unknown type in `deviceSlotToVar` | Returns `juce::var()` (null/void) |
| Unknown type in `deviceVarToSlot` | Returns `DeviceSlot{}` (empty id, default instance) |
| Missing "type" field in `varToSlot` input | Returns empty slot. No crash. |
| Missing fields in `varToSlot` input | Use documented defaults (same as current `deviceFromVar`) |
| Extra unknown fields in `varToSlot` | Silently ignored (forward compat) |
| `nullptr` registry in dispatch | Assert or return empty |

---

## H. Tests

### H.1 Existing tests that must continue to pass

| Test file | What it validates |
|-----------|-------------------|
| `engine_juce/tests/project_serialization_test.cpp` | Save/load round-trip, type strings in JSON, param values survive load |
| `engine_juce/tests/device_registry_test.cpp` | Registry type lookup, default creation, known types count |
| `engine_juce/tests/device_types_test.cpp` | Per-type param set, playback node build, toSnapshotState/slotFromSnapshot round-trip |
| `engine_juce/tests/device_chain_test.cpp` | Audio DSP processing unchanged |
| `engine_juce/tests/gate_device_test.cpp` | Gate-specific processing |
| `engine_juce/tests/effect_device_modulation_test.cpp` | Modulation on effect devices |
| `engine_juce/tests/effect_device_automation_test.cpp` | Automation on effect devices |
| `engine_juce/tests/remove_device_test.cpp` | Device removal integration |

### H.2 New tests to add

Each device package (1–14) should add a simple round-trip test in its own style. Since the engine uses standalone `int main()` executables, these can be:

**Option A**: Add an assertion to the existing `device_types_test.cpp` or `device_registry_test.cpp` (one file, growing per device).

**Option B**: Create a new `engine_juce/tests/device_slot_serialization_test.cpp` that tests `slotToVar` → `varToVar` → `slotToSlot` round-trip for all device types.

**Recommended**: Option B — a single new test file:

```cpp
// engine_juce/tests/device_slot_serialization_test.cpp
// Validates that slotToVar/varToSlot round-trip produces identical slots.

#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/ProjectJson.hpp"  // for deviceSlotToVar / deviceVarToSlot
#include <cstdlib>
#include <cmath>

int main() {
    const auto registry = audioapp::DeviceRegistry::createBuiltIn();

    // Test each known device type
    for (const auto& typeId : registry.knownTypes()) {
        audioapp::DeviceSlot original = registry.createDefault(typeId, "test-device");
        // Modify a parameter
        auto result = registry.setParameter(original, modifiableParamForType(typeId), 0.75f);
        if (!result.handled) continue;

        // Round-trip
        const auto json = audioapp::deviceSlotToVar(original, registry);
        const audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);

        // Verify identity
        if (restored.id != original.id) return EXIT_FAILURE;
        if (std::abs(restored.gain - original.gain) > 0.001f) return EXIT_FAILURE;
        // ... more assertions
    }

    return EXIT_SUCCESS;
}
```

---

## I. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Backward compatibility**: JSON schema change breaks loading old project files | High | Each `varToSlot` implementation must handle legacy field renames (documented in current `deviceFromVar`). Test with existing test data. |
| **Thread safety**: Control thread uses `DeviceRegistry::find()`, audio thread uses `DeviceNodePlayback`. No shared mutable state. | Low | Both new methods are called only on control thread (same as current serialization). No change to audio-thread code paths. |
| **Incomplete migration**: Some device types miss `slotToVar`/`varToSlot` implementation | Medium | Package 0 provides a fallback to old `deviceToVar`/`deviceFromVar`. Each device package removes one branch from the fallback chain. |
| **DeviceState → DeviceSlot → DeviceState round-trip loses information** | Medium | The snapshot path (DeviceState → deviceToVar) remains unchanged. Only the persistence path (DeviceSlot → slotToVar) is refactored. No round-trip loss. |
| **DeviceSlot vs DeviceState for persistence**: `ProjectEngine` stores `DeviceSlot` internally but persists via `DeviceState`. Inconsistency possible. | Low | The refactored path goes directly from `DeviceSlot` to JSON, eliminating the `DeviceState` intermediary for persistence. |
| **Flutter bridge expects DeviceState fields in snapshot JSON** | None | Snapshot path is NOT refactored in this contract. Only project file persistence (save/load) uses the new per-device serialization. |
| **New virtual method on IDeviceType breaks ODR if not all subclasses implement** | Low | Pure virtual ensures compile-time error if a device type doesn't implement. Package 0 adds them as pure virtual. |

---

## J. Integration Plan

### Phase A — Foundation (Package 0)
1. Add `slotToVar`/`varToSlot` pure virtuals to `IDeviceType`
2. Add `deviceSlotToVar`/`deviceVarToSlot` dispatching functions to `ProjectJson.cpp`
3. Add registry-aware overloads `deviceToVar(DeviceState, DeviceRegistry)` / `deviceFromVar(var, DeviceRegistry)`
4. Update `ProjectEngine.cpp` persistence to use new overloads
5. Keep old if/else-if chain as fallback for un-migrated devices
6. All tests pass

### Phase B — Device migration (Packages 1–14, any order, parallel)
7. Each device package implements `slotToVar`/`varToSlot`
8. The device's if-branch is removed from the fallback chain
9. Each device package is tested independently

### Phase C — Cleanup (Package 15)
10. After ALL devices are migrated, remove the entire if/else-if fallback from `ProjectJson.cpp`
11. Remove the `DeviceState`-only overloads (keep the registry overloads)
12. Final verification: all tests pass

---

## K. Recommended Implementation Order

1. **Package 0** — Interface + dispatch + ProjectEngine integration (1 implementation worker)
2. **Packages 1–2** — TrackGain and Oscillator first (simplest, good validation) (2 workers, parallel)
3. **Packages 3–6** — Dynamics devices (gate, compressor, expander, limiter) (4 workers, parallel)
4. **Packages 7–8** — Sampler and SubtractiveSynth (most fields, lots of legacy handling) (2 workers, parallel)
5. **Packages 9–14** — BassSynth + drum generators (5 workers, parallel)
6. **Package 15** — Integration cleanup (1 worker)

### Why this order
- Start with the simplest devices to validate the pattern before tackling complex ones
- Dynamics devices (3–6) share the meters pattern, good to do together for consistency
- Sampler and SubtractiveSynth have the most fields and legacy logic — do after the pattern is proven
- Drum generators (10–14) are simple but numerous — can batch in parallel
- Integration cleanup last, when all devices are migrated

---

## L. Worker Instructions for Implementation Agents

Each worker implementing a device package (Packages 1–14) MUST:

1. **Obey canonical names** from section A. Do not invent synonyms.
2. **Stay within assigned files** listed in section D. Do not modify `DeviceState.hpp`, `DeviceSlot.hpp`, `DeviceChain.hpp`.
3. **Not change existing method signatures** on `IDeviceType` (except adding the two new methods).
4. **Maintain exact JSON compatibility** — the output of `slotToVar` must match the current `deviceToVar` output field-for-field, including type (double for all numeric values).
5. **Include legacy field handling** — copy the legacy field rename logic from current `deviceFromVar` into `varToSlot`. Test with legacy format.
6. **Not touch audio thread code** — all changes are in control-thread files.
7. **Not redesign architecture** — this is a relocation of existing serialization knowledge, not a redesign.
8. **Not touch the `DeviceState` flat struct** — it remains for bridge snapshots.
9. **Stop and report** if the contract is missing information (field defaults, legacy mappings, edge cases).

If a worker encounters a missing contract item (e.g., a field default value not documented here), they should:
- Read the current implementation in `ProjectJson.cpp` lines 79–428 for the authoritative values
- Use the same defaults as the current code
- Report the discrepancy

---

## M. Success Criteria (Checklist)

- [ ] `ProjectJson.cpp` contains zero `type == "..."` string comparisons in serialization code
- [ ] Each device type in `src/devices/*DeviceType.cpp` implements both `slotToVar` and `varToSlot`
- [ ] All existing C++ tests pass unchanged
- [ ] `project_serialization_test.cpp` round-trip works (save → parse → save → parse produces identical bytes)
- [ ] Project files saved before the refactoring load correctly after (backward compat)
- [ ] Snapshot JSON sent to Flutter is unchanged
- [ ] Audio thread code (`DeviceChain.cpp`, DSP modules) has zero changes
- [ ] `DeviceState.hpp` has zero changes
