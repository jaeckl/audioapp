# Device Panel State — Data Contracts

> Part of the Device Panel State feature. This document defines panel types, device→panel
> mappings, data flow, serialization contracts, and vertical work packages.
>
> Canonical vocabulary, architecture, and API contracts are in sibling files
> `01-architecture.md`, `02-canonical-vocabulary.md`, `03-api-contracts.md`.

---

## Table of contents

1. [Canonical vocabulary](#1-canonical-vocabulary)
2. [Panel type definitions](#2-panel-type-definitions)
3. [Device → Panel mapping table](#3-device--panel-mapping-table)
4. [Control thread data flow](#4-control-thread-data-flow)
5. [Audio thread data flow](#5-audio-thread-data-flow)
6. [Serialization contract](#6-serialization-contract)
7. [Modulation/automation contract](#7-modulationautomation-contract)
8. [Work package breakdown](#8-work-package-breakdown)
9. [Open questions / risks](#9-open-questions--risks)

---

## 1. Canonical vocabulary

All names below are **binding**. Implementation agents must not invent synonyms.

| Concept | Canonical name | File (proposed path) | Notes |
|---------|---------------|---------------------|-------|
| Empty (no-op) input panel | `EmptyPanel` | `engine_juce/include/audioapp/devices/DevicePanelTypes.hpp` | `std::monostate` analogue |
| Mono (gain-only) output panel | `MonoOutputPanel` | same | No pan field |
| Stereo (gain+pan) output panel | `StereoOutputPanel` | same | Has both gain and pan |
| Dynamics input panel (trim) | `DynamicsInputPanel` | same | Has trim field |
| All input panel alternatives | `InputPanelParams` | same | `std::variant<EmptyPanel, DynamicsInputPanel>` |
| All output panel alternatives | `OutputPanelParams` | same | `std::variant<EmptyPanel, MonoOutputPanel, StereoOutputPanel>` |
| Unified device state | `DeviceState` | `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | Wraps `DeviceInstance` + panels + bypass |
| Updated device slot | `DeviceSlot` | same | Loses loose `gain`/`pan`/`bypassed`; holds `DeviceState` |
| Enumeration template method | `enumerate(auto&& cb) const` | `DevicePanelTypes.hpp` | Used for serialization, modulation, automation |
| Encoded common gain param ID | `kEncodedCommonGain` | `engine_juce/include/audioapp/AutomationTypes.hpp` | Already exists (= 0) |
| Encoded common pan param ID | `kEncodedCommonPan` | same | Already exists (= 1) |
| Panel param ID prefix | `"gain"`, `"pan"`, `"trim"` | — | Flat string IDs for modulation bindings |
| Stereo/mono decision trait | `outputPanelForKind(kind)` | `DevicePanelTypes.hpp` or `DeviceRegistry` | Maps device kind → output panel variant |
| Panel-to-NodePlayback bridge | `writeOutputPanelToNode(...)` | — | Copies `MonoOutputPanel.gain` or `StereoOutputPanel.{gain,pan}` to `DeviceNodePlayback` |
| Panel setter dispatcher | `setPanelParameter(...)` | `DeviceStripParams.hpp` | Replaces `setStripParameter` for panel-scoped params |

---

## 2. Panel type definitions

All panel types live in a new header:

**`engine_juce/include/audioapp/devices/DevicePanelTypes.hpp`**

```cpp
#pragma once

namespace audioapp {

// ── Input panel alternatives ──────────────────────────────────────────

/// Empty input panel — used for devices with no input-stage controls.
struct EmptyPanel {
    void enumerate(auto&& /*cb*/) const {
        // no-op
    }
};

/// Input trim + metering for dynamics processors.
struct DynamicsInputPanel {
    float trim = 1.0f;           // input gain trim, [0, 1]

    void enumerate(auto&& cb) const {
        cb("trim", trim);
    }
};

// ── Output panel alternatives ─────────────────────────────────────────

/// Mono output — gain only. Used for mono drum generators (kick, snare, etc.).
struct MonoOutputPanel {
    float gain = 1.0f;           // output gain, [0, 1]

    void enumerate(auto&& cb) const {
        cb("gain", gain);
    }
};

/// Stereo output — gain + pan. Used for all stereo-capable devices.
struct StereoOutputPanel {
    float gain = 1.0f;           // output gain, [0, 1]
    float pan  = 0.5f;           // pan, [0, 1] where 0.5 = centre

    void enumerate(auto&& cb) const {
        cb("gain", gain);
        cb("pan",  pan);
    }
};

// ── Variant aliases ───────────────────────────────────────────────────

using InputPanelParams  = std::variant<EmptyPanel, DynamicsInputPanel>;
using OutputPanelParams = std::variant<EmptyPanel, MonoOutputPanel, StereoOutputPanel>;

} // namespace audioapp
```

### Contract rules for `enumerate()`

1. The callback receives `(const char* fieldName, float& fieldValue)`.
2. Field names are flat strings: `"gain"`, `"pan"`, `"trim"`.
3. The callback is used for:
   - Serialization (read each field into a `juce::DynamicObject`)
   - Deserialization (write each field from a parsed value)
   - Modulation (apply modulation amount to the float ref)
   - Automation (snap the float to an envelope value)
4. The `enumerate` signature is a **constrained template**:

   ```cpp
   template<typename Fn>
       requires std::invocable<Fn&, const char*, float&>
   void enumerate(Fn&& cb) const;
   ```

5. New panel types added in the future must follow the same `enumerate` pattern.

### Contract rules for defaults

- `MonoOutputPanel::gain = 1.0f` (unit gain)
- `StereoOutputPanel::gain = 1.0f`, `StereoOutputPanel::pan = 0.5f` (centre)
- `DynamicsInputPanel::trim = 1.0f` (no attenuation)
- `EmptyPanel` has no fields

---

## 3. Device → Panel mapping table

### Mapping rules

1. **Mono drum generators** → `MonoOutputPanel` (gain only). These devices are fundamentally
   mono: Kick, Snare, Clap, Cymbal, Crash.
2. **All other devices** → `StereoOutputPanel` (gain + pan).
3. **Dynamics devices** (Gate, Compressor, Expander, Limiter) → additionally
   `DynamicsInputPanel` with `trim` that replaces the device-specific `inputGain` param.
4. **TrackGain** → `MonoOutputPanel` (gain only; it IS the track's gain, no pan or bypass).
   Input panel: `EmptyPanel`.

### The 22 device types

| # | Device type ID | TypeId constant | Class | Input panel | Output panel | Bypassable? | Notes |
|---|---------------|----------------|-------|-------------|--------------|-------------|-------|
| 1 | `simple_oscillator` | `kOscillator` | `OscillatorDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 2 | `simple_sampler` | `kSampler` | `SamplerDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 3 | `track_gain` | `kTrackGain` | `TrackGainDeviceType` | `EmptyPanel` | `MonoOutputPanel` | **No** | Cannot be bypassed; `gain` IS the track gain |
| 4 | `subtractive_synth` | `kSubtractiveSynth` | `SubtractiveSynthDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 5 | `kick_generator` | `kKickGenerator` | `KickGeneratorDeviceType` | `EmptyPanel` | `MonoOutputPanel` | Yes | Mono drum |
| 6 | `snare_generator` | `kSnareGenerator` | `SnareGeneratorDeviceType` | `EmptyPanel` | `MonoOutputPanel` | Yes | Mono drum |
| 7 | `clap_generator` | `kClapGenerator` | `ClapGeneratorDeviceType` | `EmptyPanel` | `MonoOutputPanel` | Yes | Mono drum |
| 8 | `cymbal_generator` | `kCymbalGenerator` | `CymbalGeneratorDeviceType` | `EmptyPanel` | `MonoOutputPanel` | Yes | Mono drum |
| 9 | `crash_generator` | `kCrashGenerator` | `CrashGeneratorDeviceType` | `EmptyPanel` | `MonoOutputPanel` | Yes | Mono drum |
| 10 | `gate` | `kGate` | `GateDeviceType` | `DynamicsInputPanel` | `StereoOutputPanel` | Yes | inputGain → trim |
| 11 | `compressor` | `kCompressor` | `CompressorDeviceType` | `DynamicsInputPanel` | `StereoOutputPanel` | Yes | inputGain → trim |
| 12 | `expander` | `kExpander` | `ExpanderDeviceType` | `DynamicsInputPanel` | `StereoOutputPanel` | Yes | inputGain → trim |
| 13 | `limiter` | `kLimiter` | `LimiterDeviceType` | `DynamicsInputPanel` | `StereoOutputPanel` | Yes | inputGain → trim |
| 14 | `bass_synth` | `kBasSynth` | `BassSynthDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 15 | `phase_mod_synth` | `kPhaseModSynth` | `PhaseModSynthDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 16 | `delay` | `kDelay` | `DelayDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 17 | `reverb` | `kReverb` | `ReverbDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 18 | `chorus` | `kChorus` | `ChorusDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 19 | `phaser` | `kPhaser` | `PhaserDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 20 | `filter` | `kFilter` | `FilterDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 21 | `four_band_eq` | `kFourBandEq` | `FourBandEqDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |
| 22 | `frequency_shifter` | `kFrequencyShifter` | `FrequencyShifterDeviceType` | `EmptyPanel` | `StereoOutputPanel` | Yes | |

### Dynamics inputGain migration

Currently, dynamics devices carry `inputGain` as a field inside `GateParams`,
`CompressorParams`, `ExpanderParams`, and `LimiterParams`. Under the new design:

- `inputGain` is **removed** from those parameter structs.
- The value is stored in `DynamicsInputPanel::trim`.
- During `buildPlaybackNode`, the dynamics processor reads `trim` from the input
  panel and copies it to a new `inputGain` field on the playback params.
- Serialization: `"trim"` is written/read from the `"inputPanel"` sub-object;
  `"inputGain"` is no longer written to the `"parameters"` sub-object.

**Backward compatibility:** During deserialization (`varToSlot`), if `"inputGain"`
is found in the legacy `"parameters"` object but no `"inputPanel"`/`"trim"` exists,
migrate by copying `inputGain` → `DynamicsInputPanel.trim`.

---

## 4. Control thread data flow

### 4.1 Setting panel parameters

The existing `device_strip::setStripParameter()` in `DeviceStripParams.hpp` currently
dispatches `"gain"`, `"pan"`, `"bypass"` to loose `DeviceSlot` fields. Under the new design:

- `setStripParameter` is replaced by `setPanelParameter` which dispatches to the
  correct panel variant.
- `"gain"` → sets `outputPanel.gain` on whichever panel variant is active.
- `"pan"` → sets `outputPanel.pan` — **rejected** (returns `false`) if the
  active variant is `MonoOutputPanel`.
- `"bypass"` → sets `state.bypassed` — **rejected** (returns `false`) if the
  device is `TrackGain`.
- `"trim"` → sets `inputPanel.trim` — only valid when `inputPanel` holds
  `DynamicsInputPanel`.

```cpp
// Proposed signature in DeviceStripParams.hpp
namespace audioapp::device_strip {

bool setPanelParameter(DeviceSlot& slot,
                       std::string_view parameterId,
                       float value) noexcept;

} // namespace audioapp::device_strip
```

### 4.2 Device-type `setParameter` dispatch

Each `IDeviceType::setParameter()` implementation currently calls
`device_strip::setStripParameter(slot, parameterId, value)` as a first-step
gate. Under the new design it calls `device_strip::setPanelParameter(...)` instead.

The rest of `setParameter` handles device-specific params (unchanged).

### 4.3 Device-type `modulatableParams`

Each `modulatableParams()` implementation currently returns `{"gain", "pan", ...deviceParams}`.
Under the new design:

- If the device has `StereoOutputPanel`: return `{"gain", "pan", ...}`.
- If the device has `MonoOutputPanel`: return `{"gain", ...}`.
- If the device has `DynamicsInputPanel`: the list should eventually include `"trim"`.
- Implementations derive these from the panel type rather than hardcoding.

**Transition approach:** Hardcoded strings remain during migration but must match
the panel assignment. Test code must verify consistency.

### 4.4 Building playback nodes

`rebuildTrackPlaybackLocked()` in `ProjectEngine.cpp` currently copies:

```cpp
node.gain = device.gain;       // ← will read from state.outputPanel
node.pan = device.pan;         // ← will read from state.outputPanel (if Stereo)
node.bypassed = device.bypassed; // ← will read from state.bypassed
```

Under the new design:

```cpp
const auto& state = device.state;
node.bypassed = state.bypassed;

// Dispatch on output panel variant
if (auto* mono = std::get_if<MonoOutputPanel>(&state.outputPanel)) {
    node.gain = mono->gain;
    node.pan  = 0.5f;  // default centre, no pan control
} else if (auto* stereo = std::get_if<StereoOutputPanel>(&state.outputPanel)) {
    node.gain = stereo->gain;
    node.pan  = stereo->pan;
}
```

Input panel data is NOT copied into `DeviceNodePlayback` — it is consumed during
`buildPlaybackNode()` and baked into the playback params at that time.

### 4.5 Device-type `buildPlaybackNode`

Currently, many instruments copy `slot.gain` into their params (e.g.
`KickGeneratorDeviceType` line 72: `params.gain = slot.gain`). Under the new
design, these read from `state.outputPanel`:

```cpp
void KickGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot, ...) {
    auto params = std::get<KickGeneratorParams>(slot.instance);
    // Before: params.gain = slot.gain;
    // After:
    const auto& panel = std::get<MonoOutputPanel>(slot.state.outputPanel);
    params.gain = panel.gain;
    // pan is NOT copied (mono device)
    ...
}
```

For stereo devices, both `gain` and `pan` are read.

For dynamics devices, `buildPlaybackNode` additionally reads `trim` from the input
panel and writes it to the playback `inputGain` field.

---

## 5. Audio thread data flow

### 5.1 Data structures (unchanged where possible)

The audio thread reads from `DeviceNodePlayback` (lock-free snapshot) and
`DeviceProcessor` (arena-allocated). These retain their loose `gain` and `pan`
fields for now, so the audio processing loop is not disrupted during migration.

```cpp
// DeviceNodePlayback (unchanged during Packages 1-5)
struct DeviceNodePlayback {
    DeviceNodeKind kind;
    std::string deviceId;
    bool bypassed = false;
    float gain = 1.0f;
    float pan = 0.5f;
    int8_t meterSlot = -1;
    DeviceVariantParams params;
};

// DeviceProcessor (unchanged during Packages 1-5)
class DeviceProcessor {
    bool bypassed = false;
    int8_t meterSlot = -1;
    float gain = 1.0f;
    float pan = 0.5f;
};
```

**Package 7** migrates these to read from panel data instead.

### 5.2 Control → Audio bridge

The existing bridge in `ProjectEngine::rebuildTrackPlaybackLocked()` (lines 1136–1144)
and `buildProcessorChain()` (lines 121–126 in `DeviceChainOrchestrator.cpp`) is
updated to unpack panel data into the flat `gain`/`pan` fields on `DeviceNodePlayback`
and `DeviceProcessor`. The audio thread sees no API change until Package 8.

### 5.3 Orchestrator loop

The orchestrator (`DeviceChainOrchestrator::processChain`) is **unchanged**:

1. Initializes `perFrameGain`/`perFramePan` from `proc->gain`/`proc->pan`
2. Applies timeline automation (gain/pan clips write directly to per-frame arrays)
3. Applies LFO modulation to gain/pan
4. For non-instrument, non-TrackGain nodes: `block.applyPerFrameGain(s.perFrameGain)`
5. The `perFramePan` array is available for future stereo panning but is not
   currently applied in the loop body (left for future stereo routing enhancement)

### 5.4 Per-frame arrays (DeviceChainScratch)

`DeviceChainScratch` remains unchanged:

```cpp
float perFrameGain[kScratchFrames];  // initialized from proc->gain
float perFramePan[kScratchFrames];   // initialized from proc->pan
```

When pan is not supported (mono drum → `MonoOutputPanel`), the `perFramePan` array
is initialized to 0.5f (centre). Modulation/automation of pan is still possible but
has no audible effect — this is correct behaviour.

### 5.5 Live instrument data flow

`LiveInstrumentSnapshot` (used by `LivePerformanceMixer`) retains its loose `gain`
field. During `buildLiveInstrument()`, the gain is read from the output panel:

```cpp
bool KickGeneratorDeviceType::buildLiveInstrument(...) {
    params.gain = slot.gain;
    // becomes:
    params.gain = std::get<MonoOutputPanel>(slot.state.outputPanel).gain;
    ...
}
```

---

## 6. Serialization contract

### 6.1 JSON layout (v2 with panels)

```json
{
    "id": "device-uuid",
    "type": "kick_generator",
    "inputPanel": {
        "type": "empty"
    },
    "outputPanel": {
        "type": "mono",
        "gain": 0.85
    },
    "bypass": 0.0,
    "parameters": {
        "kickModel": 0.0,
        "kickPitch": 0.55,
        ...
    }
}
```

For stereo devices:

```json
{
    "id": "device-uuid",
    "type": "compressor",
    "inputPanel": {
        "type": "dynamics",
        "trim": 0.9
    },
    "outputPanel": {
        "type": "stereo",
        "gain": 1.0,
        "pan": 0.5
    },
    "bypass": 0.0,
    "parameters": {
        "compThreshold": 0.55,
        ...
    }
}
```

### 6.2 Panel serialization helpers

Each panel type implements `toVar()` and `fromVar()`:

```cpp
// In DevicePanelTypes.hpp

juce::var inputPanelToVar(const InputPanelParams& panel);
InputPanelParams inputPanelFromVar(const juce::var& obj);

juce::var outputPanelToVar(const OutputPanelParams& panel);
OutputPanelParams outputPanelFromVar(const juce::var& obj);
```

These are used by `slotToVar` and `varToSlot` in each device type.

### 6.3 Device-type `slotToVar` changes

Each device type's `slotToVar()` currently writes `gain`, `pan`, `bypass` as flat
fields in the `"parameters"` object. Under the new design:

1. Write `"inputPanel"` root-level object (type + fields)
2. Write `"outputPanel"` root-level object (type + fields)
3. Write `"bypass"` root-level field
4. Do **not** write `gain`, `pan`, or `bypass` inside `"parameters"`

```cpp
juce::var KickGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* object = new juce::DynamicObject();
    object->setProperty("id", slot.id);
    object->setProperty("type", typeId());
    object->setProperty("inputPanel", inputPanelToVar(slot.state.inputPanel));
    object->setProperty("outputPanel", outputPanelToVar(slot.state.outputPanel));
    object->setProperty("bypass", slot.state.bypassed ? 1.0 : 0.0);

    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<KickGeneratorParams>(slot.instance);
    // ... device-specific fields (no gain/pan/bypass) ...
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}
```

### 6.4 Device-type `varToSlot` changes

Each device type's `varToSlot()` currently reads `gain`, `pan`, `bypass` from
`"parameters"`. Under the new design:

1. Read `"inputPanel"` → populate `slot.state.inputPanel`
2. Read `"outputPanel"` → populate `slot.state.outputPanel`
3. Read `"bypass"` → populate `slot.state.bypassed`
4. Do **not** read `gain`/`pan`/`bypass` from `"parameters"`

### 6.5 Backward compatibility (legacy load)

When `varToSlot` encounters a JSON object **without** `"outputPanel"` (legacy format):

1. Read `gain`/`pan`/`bypass` from `"parameters"` (old behaviour)
2. Determine the device type from `"type"`
3. Construct the appropriate output panel:
   - Mono drum → `MonoOutputPanel{ .gain = oldGain }`
   - All others → `StereoOutputPanel{ .gain = oldGain, .pan = oldPan }`
4. Construct the appropriate input panel:
   - Dynamics → `DynamicsInputPanel{ .trim = oldInputGain }` (if `inputGain` exists)
   - Others → `EmptyPanel`
5. Always write `"bypass"` from old `bypass` field

This ensures old projects load correctly.

### 6.6 TrackGain special case

TrackGain currently serializes `gain` inside `"parameters"` and `pan`/`bypass` at
the object root. Under the new design:

- `"outputPanel": { "type": "mono", "gain": 0.75 }`
- `"inputPanel": { "type": "empty" }`
- `"bypass"`: not written (TrackGain cannot be bypassed)
- During deserialization, ignore or warn on `bypass` if present

---

## 7. Modulation/automation contract

### 7.1 Parameter ID scheme (unchanged)

The existing `kEncodedCommonGain = 0` and `kEncodedCommonPan = 1` remain.
The new `"trim"` param gets a new encoded ID:

```cpp
// In AutomationTypes.hpp
constexpr uint16_t kEncodedCommonTrim = 2;  // packParamId(ParamKind::Common, 2)
```

### 7.2 Modulation edge encoding

Modulation edges currently carry `localParamId` as a `uint16_t`. Existing edges
with `kEncodedCommonGain` and `kEncodedCommonPan` target the loose gain/pan
fields. Under the new design:

- `kEncodedCommonGain` and `kEncodedCommonPan` are resolved against
  `outputPanel.gain` and `outputPanel.pan` (or whichever panel holds them).
- `kEncodedCommonTrim` is resolved against `inputPanel.trim`.
- The `DeviceChainOrchestrator::applyCommonGainPanLfo` function continues to
  work unchanged because it reads/writes the per-frame arrays.

### 7.3 Automation clip targeting

Automation clips carry `localParamId` and target the same IDs. The timeline
automation loop in `DeviceChainOrchestrator::processChain` (lines 224–237)
checks `ac.localParamId == kEncodedCommonGain` or `kEncodedCommonPan` and
writes to `perFrameGain[f]` / `perFramePan[f]`. This is unchanged — the panel
data has already been flattened into `DeviceProcessor::gain`/`pan` before the
audio thread runs.

### 7.4 Modulatable params enumeration

`modulatableParams()` for each device type must include `"gain"` (always),
`"pan"` (if `StereoOutputPanel`), and `"trim"` (if `DynamicsInputPanel`).

Helper to extract panel params:

```cpp
// In DevicePanelTypes.hpp
std::vector<std::string_view> panelModulatableParams(const InputPanelParams& input);
std::vector<std::string_view> panelModulatableParams(const OutputPanelParams& output);
```

### 7.5 Enumerate pattern for modulation

The `enumerate()` template on each panel type enables uniform modulation without
switching on the variant:

```cpp
// Example: apply LFO modulation to output panel
auto& outputPanel = slot.state.outputPanel;
std::visit([&](auto& panel) {
    panel.enumerate([&](const char* name, float& value) {
        if (std::string_view(name) == targetParam) {
            value = std::clamp(value + modAmount, 0.0f, 1.0f);
        }
    });
}, outputPanel);
```

---

## 8. Work package breakdown

### Dependencies overview

```
Package 1 (Panel types + DeviceState)
    |
    +---> Package 2 (Kick mono migration)
    |         |
    |         +---> Package 3 (All mono drums)
    |
    +---> Package 4 (Dynamics input panel)
    |
    +---> Package 5 (TrackGain special case)
    |
    +---> Package 6 (Serialization)
    |         |
    |         +---> Package 7 (buildPlaybackNode)
    |                   |
    |                   +---> Package 8 (Orchestrator)
    |
    +--- Package 9 (Flutter UI) [can start after Packages 1-3, parallel to 4-8]
```

### Package 1: Panel types + DeviceState (prerequisite)

**Behavior:** Define the new panel structs and `DeviceState`. No functional change
to any device type. All existing code continues to compile.

**Files:**
- **Create:** `engine_juce/include/audioapp/devices/DevicePanelTypes.hpp`
- **Modify:** `engine_juce/include/audioapp/devices/DeviceSlot.hpp`

**Changes to DeviceSlot.hpp:**

```cpp
struct DeviceState {
    DeviceInstance instance;       // moved from DeviceSlot
    InputPanelParams inputPanel;   // NEW
    OutputPanelParams outputPanel; // NEW
    bool bypassed = false;         // moved from DeviceSlot
};

struct DeviceSlot {
    std::string id;
    DeviceState state;             // NEW: replaces gain/pan/bypassed/instance
    // REMOVED: float gain = 1.0f;
    // REMOVED: float pan = 0.5f;
    // REMOVED: bool bypassed = false;
    // REMOVED: DeviceInstance instance;
};
```

**Compatibility shim:** Temporarily provide accessors so existing code compiles:

```cpp
// TEMPORARY compatibility layer — remove after all packages are done
inline float& legacyGain(DeviceSlot& slot) {
    return std::visit([](auto& p) -> float& {
        using T = std::decay_t<decltype(p)>;
        if constexpr (std::is_same_v<T, MonoOutputPanel>) return p.gain;
        else if constexpr (std::is_same_v<T, StereoOutputPanel>) return p.gain;
        else { static float dummy = 1.0f; return dummy; }
    }, slot.state.outputPanel);
}
```

But it's better to update all call sites in one go. The package will temporarily
break build until all call sites are updated by downstream packages.

**Files owned:** `DevicePanelTypes.hpp`, `DeviceSlot.hpp`
**Forbidden files:** Any `*DeviceType.cpp`, `*DeviceType.hpp`, `DeviceChain*.cpp`,
`ProjectEngine.cpp`, `DeviceChainOrchestrator.cpp`, or any test file.
**Acceptance criteria:**
- `DevicePanelTypes.hpp` compiles standalone
- `DeviceSlot.hpp` compiles with `DeviceState`
- No new virtual methods or RTTI required

---

### Package 2: Migrate KickGenerator to MonoOutputPanel (pilot)

**Behavior:** `KickGeneratorDeviceType` is the pilot device. It shows the complete
pattern for migrating one device to panels.

**Files:**
- `engine_juce/src/devices/KickGeneratorDeviceType.cpp`
- `engine_juce/include/audioapp/devices/KickGeneratorDeviceType.hpp` (if needed)

**Changes:**
1. `createDefault()` sets `slot.state.outputPanel = MonoOutputPanel{}`
2. `setParameter()` calls `device_strip::setPanelParameter(slot, ...)` instead of
   `setStripParameter`
3. `modulatableParams()` returns `{"gain", ...}` (drops `"pan"`)
4. `buildPlaybackNode()` reads `MonoOutputPanel::gain`
5. `buildLiveInstrument()` reads `MonoOutputPanel::gain`
6. `slotToVar()` writes `"outputPanel"` root-level object
7. `varToSlot()` reads `"outputPanel"` (with legacy fallback)
8. Tests updated to verify panel round-trip

**Files owned:**
- `engine_juce/src/devices/KickGeneratorDeviceType.cpp`
- `engine_juce/src/devices/...` (KickGenerator tests)

**Depends on:** Package 1
**Parallel with:** Packages 3, 4, 5

---

### Package 3: Migrate all mono drum devices (Snare, Clap, Cymbal, Crash)

**Behavior:** The remaining 4 mono drum generators adopt `MonoOutputPanel`.

**Files:**
- `engine_juce/src/devices/SnareGeneratorDeviceType.cpp`
- `engine_juce/src/devices/ClapGeneratorDeviceType.cpp`
- `engine_juce/src/devices/CymbalGeneratorDeviceType.cpp`
- `engine_juce/src/devices/CrashGeneratorDeviceType.cpp`

**Changes:** Same pattern as Package 2 for each device.
**Depends on:** Package 1, Package 2 (pattern established)
**Parallel with:** Packages 4, 5

---

### Package 4: Migrate dynamics devices to DynamicsInputPanel

**Behavior:** Gate, Compressor, Expander, Limiter gain `DynamicsInputPanel` with
`trim` replacing `inputGain`. Output panel is `StereoOutputPanel` (already standard).

**Files:**
- `engine_juce/src/devices/GateDeviceType.cpp`
- `engine_juce/src/devices/CompressorDeviceType.cpp`
- `engine_juce/src/devices/ExpanderDeviceType.cpp`
- `engine_juce/src/devices/LimiterDeviceType.cpp`
- `engine_juce/include/audioapp/DynamicsProcessor.hpp` (remove `inputGain` from structs)

**Changes:**
1. `GateParams`, `CompressorParams`, `ExpanderParams`, `LimiterParams` lose
   `inputGain` field.
2. `createDefault()` sets `slot.state.outputPanel = StereoOutputPanel{}` AND
   `slot.state.inputPanel = DynamicsInputPanel{}`.
3. `setParameter()` handles `"inputGain"` by routing to `DynamicsInputPanel::trim`.
   Handle `"trim"` as the canonical name.
4. During `buildPlaybackNode()`: read `trim` from input panel, write to
   playback param's `inputGain` field.
5. `slotToVar()/varToSlot()`: panel serialization + legacy `inputGain` fallback.
6. Tests: verify inputGain round-trips as trim.

**Depends on:** Package 1
**Parallel with:** Packages 2, 3, 5

---

### Package 5: TrackGain special case

**Behavior:** TrackGain uses `MonoOutputPanel`, cannot be bypassed, cannot have pan.

**Files:**
- `engine_juce/src/devices/TrackGainDeviceType.cpp`
- `engine_juce/include/audioapp/devices/TrackGainDeviceType.hpp` (if needed)
- `engine_juce/include/audioapp/devices/DeviceStripParams.hpp` (bypass rejection)

**Changes:**
1. `createDefault()`: `outputPanel = MonoOutputPanel{}`, `inputPanel = EmptyPanel{}`
2. `setParameter()`: only accepts `"gain"`; `"pan"` and `"bypass"` return unhandled.
3. `modulatableParams()`: returns `{"gain"}` only.
4. `slotToVar()`: writes `"outputPanel"`, skips `"bypass"`.
5. `varToSlot()`: reads `"outputPanel"`, ignores `"bypass"` if present.
6. `device_strip::setPanelParameter()` rejects `"bypass"`/`"pan"` for TrackGain.
7. Tests: verify TrackGain rejects pan/bypass, serialization round-trip.

**Depends on:** Package 1
**Parallel with:** Packages 2, 3, 4

---

### Package 6: Remaining 13 devices (non-drum, non-dynamics)

**Behavior:** All remaining devices (oscillator, sampler, synthesizers, EQ, filter,
effects) adopt `StereoOutputPanel` with `EmptyPanel` for input.

**Files:** All remaining `*DeviceType.cpp` files.
**Changes:** Same pattern as Package 2 but with `StereoOutputPanel`.
**Depends on:** Package 1
**Sequential after:** Packages 2, 3, 4 (to avoid merge conflicts on identical patterns)

---

### Package 7: Serialization consolidation + backward compatibility

**Behavior:** Finalize the serialization helpers, handle legacy project loading for
all device types. Remove `gain`/`pan`/`bypass` from `"parameters"` JSON objects.

**Files:**
- `engine_juce/src/ProjectJson.cpp` (centralized dispatch helpers)
- All `*DeviceType.cpp` files (serialization call sites)

**Changes:**
1. Implement `inputPanelToVar`/`inputPanelFromVar` and `outputPanelToVar`/
   `outputPanelFromVar` in `DevicePanelTypes.hpp`.
2. Update each device type's `slotToVar` to use the new helpers.
3. Update each device type's `varToSlot` to use the new helpers with legacy
   fallback.
4. Add a unit test that loads a v1 (legacy) JSON, verifies panels are populated.
5. Add a unit test that round-trips a v2 (panel) JSON.

**Depends on:** Packages 2–6
**Parallel with:** — (sequential)

---

### Package 8: buildPlaybackNode + orchestrator updates

**Behavior:** All `buildPlaybackNode()` and `buildLiveInstrument()` methods read
from panels instead of `slot.gain`/`slot.pan`. The orchestrator bridge in
`ProjectEngine::rebuildTrackPlaybackLocked` is updated.

**Files:**
- All `*DeviceType.cpp` files (buildPlaybackNode, buildLiveInstrument)
- `engine_juce/src/ProjectEngine.cpp` (rebuildTrackPlaybackLocked)
- `engine_juce/src/DeviceChainOrchestrator.cpp` (buildProcessorChain)

**Changes to ProjectEngine.cpp (lines 1136–1144):**

```cpp
// Before:
node.bypassed = device.bypassed;
node.gain = device.gain;
node.pan = device.pan;

// After:
const auto& state = device.state;
node.bypassed = state.bypassed;
std::visit([&](const auto& panel) {
    using T = std::decay_t<decltype(panel)>;
    if constexpr (std::is_same_v<T, MonoOutputPanel>) {
        node.gain = panel.gain;
        node.pan = 0.5f;
    } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
        node.gain = panel.gain;
        node.pan = panel.pan;
    }
}, state.outputPanel);
```

**Depends on:** Packages 2–6
**Parallel with:** — (sequential after Package 7)

---

### Package 9: Remove loose fields from DeviceNodePlayback + DeviceProcessor

**Behavior:** After all call sites are updated, remove the loose `gain`/`pan` fields
from audio-thread structures and encapsulate them inside a panel-like struct.

**Files:**
- `engine_juce/include/audioapp/DeviceChain.hpp` (DeviceNodePlayback)
- `engine_juce/include/audioapp/dsp/DeviceProcessor.hpp`
- `engine_juce/include/audioapp/DeviceChainScratch.hpp` (perFrameGain/Pan remain)
- `engine_juce/src/DeviceChainOrchestrator.cpp`

**This is a future/optional package** — deferred until the panel design has
stabilized on the control thread.

---

### Package 10: Flutter UI updates

**Behavior:** The Flutter UI shows the correct panel widgets based on device type.
Mono drum devices show gain-only (no pan slider). Dynamics devices show trim control.

**Dependencies:** Can start after Packages 1–3 (panel types + mono drums) are
complete and deployed to the device. Parallel with Packages 4–8.

**Files (Flutter):**
- `app_flutter/lib/...` (device panel widgets)
- `app_flutter/lib/...` (method channel mapping)

**Details:** To be specified in a separate Flutter UI contract document.

---

## 9. Open questions / risks

### 9.1 `perFramePan` not applied in orchestrator

The `perFramePan` array is initialized and modulated but never consumed by
`AudioBlock`. It is a **latent feature** — the pan values flow through the
system but have no audible effect currently. This means:

- **Risk:** Implementers might incorrectly assume `perFramePan` is applied
  somewhere downstream. It is NOT.
- **Decision:** The panel state work does NOT fix this. Pan remains "stored but
  unused" in the audio path. This is a separate feature tracked elsewhere.

### 9.2 Drum generators currently list `"pan"` in modulatableParams

Even though they're mono, every drum generator includes `"pan"` in
`modulatableParams()`. After migration to `MonoOutputPanel`:

- `"pan"` must be **removed** from `modulatableParams()` for these devices.
- **Risk:** Existing projects with pan automation on drum generators will lose
  those automation clips (they reference `"pan"` param IDs that no longer exist
  for that device).
- **Mitigation:** Check ProjectEngine if there are stored automation clips with
  drum-generator device index + pan param ID. Log a warning during load.

### 9.3 `DynamicsInputPanel.trim` vs existing `inputGain`

Dynamics params currently store `inputGain` as a 0–1 float. Under the new design,
this moves to `DynamicsInputPanel::trim`.

- **Risk:** The `buildPlaybackNode` for dynamics processors needs to copy trim
  into the playback params. Currently these params are directly passed as-is
  (see `CompressorDeviceType::buildPlaybackNode`: `out.params = params;`). After
  migration, `inputGain` is no longer in `params` — the processor must read it
  from somewhere else.
- **Mitigation:** Either (a) keep `inputGain` in the playback param struct and
  have `buildPlaybackNode` copy trim into it, or (b) add `trim` to the playback
  struct. Option (a) is less invasive.

### 9.4 `DeviceSlot::id` vs `DeviceState`

Should `DeviceSlot::id` move into `DeviceState`? Currently:

```cpp
struct DeviceSlot {
    std::string id;       // owned by the slot
    DeviceState state;    // would contain everything else
};
```

- `id` is used by meters (`deviceMeterIds_[i] != device.id`) and project
  serialization. Keeping it on `DeviceSlot` is cleaner since `id` is an identity
  attribute, not a state attribute.
- **Decision:** Keep `id` on `DeviceSlot`. `DeviceState` contains instance,
  panels, and bypass.

### 9.5 `TrackGain` bypass in legacy projects

Legacy TrackGain serialization writes `bypass` to the root object. Under the new
design, TrackGain cannot be bypassed. Legacy projects that saved `bypass: 1.0` on
TrackGain will silently lose that flag. This is correct behaviour — TrackGain
should never have been bypassable.

### 9.6 Preview preset path

`EngineHost_commands.cpp` accesses `slot.gain` extensively (lines 666–720).
These call sites must be updated to read from `slot.state.outputPanel`.

**Risk:** The preview preset path has multiple `slot.gain` reads scatted across
different `std::holds_alternative` branches. Each branch must be updated
individually.

### 9.7 Unit test impact

Every `varToSlot` test that passes `"gain"`/`"pan"` inside `"parameters"` will
need updating. The tests in `tests/device_slot_serialization_test.cpp` are most
affected. A dedicated backward-compatibility test suite is needed for legacy
JSON loading.

### 9.8 File size of DeviceSlot.hpp

`DeviceSlot.hpp` is currently 61 lines including all includes. Adding
`DevicePanelTypes.hpp` and `DeviceState` will push it past 100 lines. Consider
whether `DeviceState` should be in its own header.

**Decision:** Keep `DeviceState` in `DeviceSlot.hpp` for now. Extract when
it exceeds ~150 lines.