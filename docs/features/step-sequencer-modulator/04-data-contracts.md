# Step Sequencer Modulator — Architecture Contract

## 1. Feature Brief

The step sequencer modulator provides a programmable multi-step modulation source. The user draws a pattern of step values in a compact bar editor, then the sequencer advances through those steps at a rate determined by sync-to-tempo divisions or a free-running frequency. Direction (Forward, Reverse, PingPong, Random) and shape (Hold, Linear, Smooth) control how the pattern plays back. A single-pole smoothing filter polishes the output. Retrigger modes (Free, Sync, OnNote) match the existing modulator convention.

---

## 2. Canonical Vocabulary

| Concept | Canonical name | Type / File | Notes |
|---------|---------------|-------------|-------|
| Step sequencer modulator params | `SequencerParams` | `engine_juce/include/audioapp/modulation/ModulatorParams.hpp` | POD struct; member of `ModulatorParams` variant |
| Audio-thread modulator | `SequencerModulator` | `engine_juce/include/audioapp/modulation/SequencerModulator.hpp` + `.cpp` | Implements `IModulator` |
| Control-thread type descriptor | `SequencerModulatorType` | `engine_juce/include/audioapp/modulation/SequencerModulatorType.hpp` | Implements `IModulatorType` |
| Number of active steps | `stepCount` | `SequencerParams::stepCount` | `int`, 1–32, default 16 |
| Step value at index N | `stepValues[N]` | `SequencerParams::stepValues` | `std::array<float, 32>` in C++, `List<double>` in Dart |
| Modulator type enum | `ModulatorType::Sequencer = 3` | `engine_juce/include/audioapp/ModulationTypes.hpp` | New enum value |
| Type string ID | `"sequencer"` | `SequencerModulatorType::typeId()` | Used in JSON serialization |
| Step advance direction | `direction` (int) | `SequencerParams`, param ID `"direction"` | 0=Forward, 1=Reverse, 2=PingPong, 3=Random |
| Inter-step shape | `shape` (int) | `SequencerParams`, param ID `"shape"` | 0=Hold, 1=Linear, 2=Smooth |
| Smoothing coefficient | `smoothing` | `SequencerParams`, param ID `"smoothing"` | `float [0,1]`, single-pole lowpass |
| Step count control | `"steps"` | Param ID for Flutter→engine | Sets `stepCount` |
| Normalized rate | `rate` | `SequencerParams`, param ID `"rate"` | `float [0,1]`, used in Free retrigger mode |
| Sync division | `syncDivision` | `SequencerParams`, param ID `"syncDivision"` | 1=whole, 2=half, 3=quarter, 4=eighth, 5=sixteenth, 0=none |
| Retrigger mode | `retrigger` | `SequencerParams`, param ID `"retrigger"` | 0=Free, 1=Sync, 2=OnNote (enum `ModulatorRetrigger`) |
| Polarity | `polarity` | `SequencerParams`, param ID `"polarity"` | 0=bipolar, 1=unipolar-pos |
| Individual step value N | `"step_N"` | Param ID for Flutter→engine | N = 0..31; sets `stepValues[N]` |
| Step bar editor widget | `SequencerStepEditor` | `app_flutter/lib/features/device_strip/sequencer_step_editor.dart` | New Flutter widget |
| Sequencer direction names | `sequencerDirectionLabels` | `ModulatorTypes` in Dart | `['Fwd', 'Rev', 'P-P', 'Rnd']` |
| Sequencer shape names | `sequencerShapeLabels` | `ModulatorTypes` in Dart | `['Hold', 'Lin', 'Smth']` |
| Flutter snapshot field: steps | `sequencerSteps` | `LfoSnapshot` | `int`, maps to engine `stepCount` |
| Flutter snapshot field: direction | `sequencerDirection` | `LfoSnapshot` | `int`, maps to engine `direction` |
| Flutter snapshot field: shape | `sequencerShape` | `LfoSnapshot` | `int`, maps to engine `shape` |
| Flutter snapshot field: step values | `stepValues` | `LfoSnapshot` | `List<double>`, maps to engine `stepValues` |
| Flutter snapshot field: smoothing | `smoothing` | `LfoSnapshot` | Already exists (reused) |

### SequencerDirection enum (C++)

```cpp
enum class SequencerDirection : int {
    Forward = 0,
    Reverse = 1,
    PingPong = 2,
    RandomOrder = 3,
};
```

### SequencerShape enum (C++)

```cpp
enum class SequencerShape : int {
    Hold = 0,    // stepped output, constant within each step
    Linear = 1,  // linear ramp between step values
    Smooth = 2,  // smoothed transition (cubic or cosine interpolation)
};
```

---

## 3. API / Data Contracts

### 3.1 `SequencerParams` struct

File: `engine_juce/include/audioapp/modulation/ModulatorParams.hpp`

```cpp
#include <array>

struct SequencerParams {
    int stepCount = 16;                     // [1, 32] active step count
    float rate = 0.5f;                      // [0, 1] normalized (Free mode Hz)
    int syncDivision = 3;                   // 0=none, 1=whole, 2=half, 3=quarter, 4=eighth, 5=sixteenth
    int retrigger = 1;                      // ModulatorRetrigger: 0=Free, 1=Sync, 2=OnNote
    int direction = 0;                      // SequencerDirection: 0=Forward, 1=Reverse, 2=PingPong, 3=Random
    int shape = 0;                          // SequencerShape: 0=Hold, 1=Linear, 2=Smooth
    int polarity = 0;                       // 0=bipolar, 1=unipolar-pos
    float smoothing = 0.0f;                 // [0, 1] single-pole lowpass coefficient
    std::array<float, 32> stepValues{};     // [-1, 1] per step, zero-initialized
};
```

### 3.2 `ModulatorParams` variant update

```cpp
using ModulatorParams = std::variant<LfoParams, EnvelopeParams, RandomGeneratorParams, SequencerParams>;
```

### 3.3 `ModulatorType` enum update

File: `engine_juce/include/audioapp/ModulationTypes.hpp`

```cpp
enum class ModulatorType : int {
    Lfo = 0,
    Envelope = 1,
    RandomGenerator = 2,
    Sequencer = 3,
};
```

### 3.4 `SequencerModulatorType` contract

File: `engine_juce/include/audioapp/modulation/SequencerModulatorType.hpp`

```cpp
class SequencerModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "sequencer"; }
    int modulatorTypeValue() const override { return 3; }

    ModulatorParams createDefault() const override {
        SequencerParams p;
        p.stepCount = 16;
        p.rate = 0.5f;
        p.syncDivision = 3;     // quarter note
        p.retrigger = 1;        // Sync
        p.direction = 0;        // Forward
        p.shape = 0;            // Hold
        p.polarity = 0;         // bipolar
        p.smoothing = 0.0f;
        // stepValues default to 0.0f — all zeros, flat pattern
        return p;
    }

    // setParameter: handles "steps", "rate", "syncDivision", "retrigger",
    // "direction", "shape", "polarity", "smoothing", "step_0" … "step_31"
    // createModulator: arena.emplace<SequencerModulator>(params)
    // paramsToVar: serializes all fields + "step_N" per active step + "type":"sequencer"
    // varToParams: reads all fields + "step_N" from JSON var
};
```

**setParameter** param-to-field mapping:

| paramId | Field | Clamp |
|---------|-------|-------|
| `"steps"` | `stepCount` | `[1, 32]` |
| `"rate"` | `rate` | `[0.0, 1.0]` |
| `"syncDivision"` | `syncDivision` | `[0, 5]` |
| `"retrigger"` | `retrigger` | `[0, 2]` |
| `"direction"` | `direction` | `[0, 3]` |
| `"shape"` | `shape` | `[0, 2]` |
| `"polarity"` | `polarity` | `[0, 1]` |
| `"smoothing"` | `smoothing` | `[0.0, 1.0]` |
| `"step_N"` | `stepValues[N]` | `[-1.0, 1.0]` |

**paramsToVar** JSON output:

```json
{
  "type": "sequencer",
  "stepCount": 16,
  "rate": 0.5,
  "syncDivision": 3,
  "retrigger": 1,
  "direction": 0,
  "shape": 0,
  "polarity": 0,
  "smoothing": 0.0,
  "step_0": 0.0,
  "step_1": 0.5,
  ...
  "step_15": -0.3
}
```

Serialization rule: emit `step_N` for N in `[0, stepCount-1]`. On deserialization, read all `step_N` keys present; N > stepCount-1 are clamped to `stepCount-1` when used.

### 3.5 `SequencerModulator` audio-thread contract

File: `engine_juce/include/audioapp/modulation/SequencerModulator.hpp`

```cpp
class SequencerModulator : public IModulator {
public:
    explicit SequencerModulator(const SequencerParams& params) noexcept;
    void reset() noexcept override;
    int modulatorType() const noexcept override;
    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;
    void updateParams(const ModulatorParams& params) noexcept override;

private:
    SequencerParams params_;
    struct Runtime {
        int currentStep = 0;                    // [0, stepCount-1]
        int pingPongDir = 1;                    // 1 or -1 for PingPong
        double lastAdvanceBeat = 0.0;           // beat of last step advance
        uint32_t lastRetriggerGeneration = std::numeric_limits<uint32_t>::max();
        float smoothedValue = 0.0f;             // smoothing filter state
        double sampleClock = 0.0;               // free-running clock (Free mode)
        int randomOrder[32] = {};               // pre-shuffled indices (Random direction)
        int randomIdx = 0;                      // position in randomOrder
    };
    Runtime rt_;
};
```

**Evaluate logic for directions:**

| Direction | Behavior |
|-----------|----------|
| Forward (0) | Step index increments by 1 each step interval. Wraps to 0 when reaching `stepCount`. |
| Reverse (1) | Step index decrements by 1 each step interval. Wraps to `stepCount-1` when reaching 0. |
| PingPong (2) | Step index alternates direction at each end. Initial direction = +1. Reverses at 0 and `stepCount-1`. |
| Random (3) | Pre-shuffled order stored in `randomOrder[]`. Advances through shuffled list. When exhausted, re-shuffle. |

**Evaluate logic for shapes:**

| Shape | Behavior | Output formula |
|-------|----------|---------------|
| Hold (0) | Constant throughout step duration | `stepValues[currentStep]` |
| Linear (1) | Linear ramp from current to next step | `lerp(stepValues[current], stepValues[next], phase)` |
| Smooth (2) | Cosine-interpolated ramp | `cosineInterp(stepValues[current], stepValues[next], phase)` |

Where `phase ∈ [0, 1)` is the fraction of the current step interval elapsed, calculated as:

- **Free mode**: `sampleClock / (rateToHz(params_.rate) * sampleRate)`
- **Sync mode**: `(playheadBeat - rt_.lastAdvanceBeat) / syncDivisionBeats(params_.syncDivision)`
- **OnNote mode**: same as Sync, but resets on retrigger generation change.

**Rate-to-Hz mapping** (same as LFO/RandomGenerator):
```cpp
static float rateToHz(float normalizedRate) noexcept {
    return 0.05f + std::clamp(normalizedRate, 0.0f, 1.0f) * 7.95f;
}
```

**Sync division beat mapping** (same as existing `lfoSyncBeats`):
```cpp
static double syncDivisionBeats(int div) noexcept {
    switch (div) {
    case 0:  return 0.0;
    case 1:  return 1.0;      // whole
    case 2:  return 0.5;      // half
    case 3:  return 0.25;     // quarter
    case 4:  return 0.125;    // eighth
    case 5:  return 0.0625;   // sixteenth
    default: return 0.25;
    }
}
```

**Smoothing filter:**
```cpp
float smoothValue(float raw) noexcept {
    // Single-pole lowpass: coefficient a = smoothing param
    // a=0 → no smoothing, a=1 → fully smoothed (never reaches target)
    const float a = std::clamp(params_.smoothing, 0.0f, 1.0f);
    rt_.smoothedValue += a * (raw - rt_.smoothedValue);
    return rt_.smoothedValue;
}
```

**Polarity:**
```cpp
float applyPolarity(float value) const noexcept {
    switch (params_.polarity) {
    case 0: return value;                    // bipolar [-1, 1]
    case 1: return std::max(0.0f, value);    // unipolar-pos [0, 1]
    default: return value;
    }
}
```

### 3.6 ModulationGraph registration

File: `engine_juce/src/modulation/ModulationGraph.cpp`

Add to the constructor:
```cpp
#include "audioapp/modulation/SequencerModulatorType.hpp"

modulatorTypes_.push_back(std::make_unique<SequencerModulatorType>());
```

This must be appended **after** the existing three types so that the enum values (`Lfo=0, Envelope=1, RandomGenerator=2, Sequencer=3`) match the vector indices. The existing registration order is:

```cpp
modulatorTypes_.push_back(std::make_unique<LfoModulatorType>());            // index 0
modulatorTypes_.push_back(std::make_unique<EnvelopeModulatorType>());       // index 1
modulatorTypes_.push_back(std::make_unique<RandomGeneratorModulatorType>()); // index 2
modulatorTypes_.push_back(std::make_unique<SequencerModulatorType>());      // index 3 ← NEW
```

### 3.7 Flutter LfoSnapshot additions

File: `app_flutter/lib/bridge/project_snapshot.dart`

**New constructor parameters** with defaults:
```dart
this.sequencerSteps = 16,
this.sequencerDirection = 0,
this.sequencerShape = 0,
this.stepValues = const [],
```

**New fields**:
```dart
final int sequencerSteps;
final int sequencerDirection;
final int sequencerShape;
final List<double> stepValues;
```

**`modulatorType` getter update**:
```dart
int get modulatorType => type == 'envelope'
    ? 1
    : type == 'random_generator'
        ? 2
        : type == 'sequencer'
            ? 3
            : 0;
```

**`fromMap` — new branch** for `type == 'sequencer'`:
```dart
if (typeStr == 'sequencer') {
  // Collect step_N properties
  final steps = <double>[];
  final stepCount = (map['stepCount'] as num?)?.toInt() ?? 16;
  for (var i = 0; i < stepCount; i++) {
    final key = 'step_$i';
    final val = map[key] as num?;
    steps.add(val?.toDouble() ?? 0.0);
  }
  return LfoSnapshot(
    id: (map['id'] as num?)?.toInt() ?? 0,
    type: 'sequencer',
    sequencerSteps: stepCount,
    sequencerDirection: (map['direction'] as num?)?.toInt() ?? 0,
    sequencerShape: (map['shape'] as num?)?.toInt() ?? 0,
    retrigger: (map['retrigger'] as num?)?.toInt() ?? 1,
    rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
    syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 3,
    polarity: (map['polarity'] as num?)?.toInt() ?? 0,
    smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
    stepValues: steps,
  );
}
```

**`applyParamUpdate` — new cases**:
```dart
case 'steps':       return copyWith(sequencerSteps: value.round().clamp(1, 32));
case 'direction':   return copyWith(sequencerDirection: value.round().clamp(0, 3));
case 'shape':       return copyWith(sequencerShape: value.round().clamp(0, 2));
default:
  if (param.startsWith('step_')) {
    final idx = int.tryParse(param.substring(5));
    if (idx != null && idx >= 0 && idx < stepValues.length) {
      final newSteps = [...stepValues];
      newSteps[idx] = value.clamp(-1.0, 1.0);
      return copyWith(stepValues: newSteps);
    }
  }
  return this;
```

**`copyWith` — new optional parameters**:
```dart
int? sequencerSteps,
int? sequencerDirection,
int? sequencerShape,
List<double>? stepValues,
```

### 3.8 Flutter ModulatorTypes constants

File: `app_flutter/lib/features/device_strip/modulator_types.dart`

```dart
static const sequencer = 3;
```

Update `labelFor`:
```dart
static String labelFor(int type) => switch (type) {
  0 => 'LFO',
  1 => 'ENV',
  2 => 'RND',
  3 => 'SEQ',
  _ => '?',
};
```

Add new label arrays:
```dart
static const sequencerDirectionLabels = ['Fwd', 'Rev', 'P-P', 'Rnd'];
static const sequencerShapeLabels = ['Hold', 'Lin', 'Smth'];
```

Update `labels` for the add menu:
```dart
static const labels = ['LFO', 'Envelope', 'Random Generator', 'Sequencer'];
```

### 3.9 Parameter ID catalog (engine ↔ Flutter)

| paramId | Value type | Range | Owner | Notes |
|---------|-----------|-------|-------|-------|
| `"modulatorType"` | int | 0–3 | ModulationGraph | Special case, switches type |
| `"steps"` | int | 1–32 | Sequencer | Set step count |
| `"retrigger"` | int | 0–2 | All modulators | Free/Sync/OnNote |
| `"rate"` | float | 0–1 | LFO, RND, Sequencer | Normalized rate |
| `"syncDivision"` | int | 0–5 | LFO, Sequencer | Beat division |
| `"direction"` | int | 0–3 | Sequencer | Forward/Reverse/PingPong/Random |
| `"shape"` | int | 0–2 | Sequencer | Hold/Linear/Smooth |
| `"polarity"` | int | 0–1 | LFO, RND, Sequencer | bipolar/unipolar |
| `"smoothing"` | float | 0–1 | RND, Sequencer | Single-pole coefficient |
| `"step_N"` | float | -1–1 | Sequencer | Individual step value (N=0..31) |

---

## 4. Engine Evaluate Semantics

### Step advance timing

At each `evaluate()` call, the modulator checks whether enough time has elapsed to advance to the next step:

- **Free mode**: Compare elapsed seconds since last advance against `rateToHz(rate)` period. Free-running `sampleClock` increments by the block duration.
- **Sync mode**: Compare `playheadBeat - lastAdvanceBeat` against `syncDivisionBeats(syncDivision)`. When beat delta exceeds the division interval, advance.
- **OnNote mode**: Same advance logic as Sync. Additionally, on retrigger (detected via `retriggerGeneration` increment), reset `currentStep = 0` (or its direction-dependent start position).

### Output value calculation

1. Determine `currentStep` and intra-step `phase` based on direction and elapsed time.
2. Calculate raw value from the `stepValues[currentStep]` and (for Linear/Smooth) `stepValues[nextStep]` with interpolation.
3. Apply smoothing: `smoothedValue += smoothing * (raw - smoothedValue)`.
4. Apply polarity transform.
5. Return final value in [-1, 1].

### Thread safety

- `evaluate()` is called from the **audio thread** only. No locking required.
- `updateParams()` is called under exclusive lock from the **control thread**. It copies the `SequencerParams` struct atomically (all fields are 32-bit aligned scalars; the `std::array<float, 32>` is copied by value, which is safe on the control thread under the exclusive lock).
- `reset()` is called from the audio thread when playback starts.

---

## 5. File Ownership

| File/path | Owner WP | Allowed changes | Forbidden changes |
|-----------|----------|-----------------|-------------------|
| `engine_juce/include/audioapp/ModulationTypes.hpp` | WP1 | Add `Sequencer = 3` to `ModulatorType` enum | No changes to existing enum values or other enums |
| `engine_juce/include/audioapp/modulation/ModulatorParams.hpp` | WP1 | Add `#include <array>`, add `SequencerParams` struct, add `SequencerParams` to `ModulatorParams` variant | No changes to existing structs or variant alternatives |
| `engine_juce/src/modulation/ModulationGraph.cpp` | WP1 | Add `#include "SequencerModulatorType.hpp"`, add registration line | No changes to existing logic, clear, rebuild, or parameter update methods |
| `engine_juce/include/audioapp/modulation/SequencerModulator.hpp` | WP2 | New file — full class definition | Must not touch any other file |
| `engine_juce/src/modulation/SequencerModulator.cpp` | WP2 | New file — evaluate implementation | Must not touch any other file |
| `engine_juce/include/audioapp/modulation/SequencerModulatorType.hpp` | WP3 | New file — full class definition | Must not touch any other file |
| `app_flutter/lib/bridge/project_snapshot.dart` | WP4 | Add sequencer fields to `LfoSnapshot`, update `fromMap`, `applyParamUpdate`, `copyWith`, `modulatorType` | No changes to other snapshot classes or existing LfoSnapshot field semantics |
| `app_flutter/lib/features/device_strip/modulator_types.dart` | WP4 | Add `sequencer`, update `labelFor`, add label arrays | No changes to existing constants/labels |
| `app_flutter/lib/features/device_strip/modulator_properties_panel.dart` | WP5 | Add `_sequencerLayout()` and branching in `build()` | Must not modify existing `_lfoLayout`, `_envelopeLayout`, `_randomGeneratorLayout` |
| `app_flutter/lib/features/device_strip/modulation_grid.dart` | WP6 | Add Sequencer to add menu list tiles | Must not modify existing modulator tiles or grid layout |
| `app_flutter/lib/features/device_strip/sequencer_step_editor.dart` | WP5 | New widget — step bar editor (CustomPainter) | Must not touch any other file |
| `app_flutter/lib/features/device_strip/sequencer_preview_painter.dart` | WP6 | New widget — mini step preview for grid tiles | Must not touch any other file |

**Shared file requiring care**: `project_snapshot.dart` is touched by WP4 but read by WP5 and WP6. WP4 must complete before WP5/WP6 begin. The LfoSnapshot class with sequencer fields must be committed before panel and grid changes can compile.

---

## 6. Vertical Work Packages

### WP1: Engine params + type registration (PREREQUISITE)

**User-visible behavior**: None (infrastructure). Enables subsequent work.

**Files assigned**: 
- `engine_juce/include/audioapp/modulation/ModulatorParams.hpp`
- `engine_juce/include/audioapp/ModulationTypes.hpp`
- `engine_juce/src/modulation/ModulationGraph.cpp`

**Details**:
- Add `Sequencer = 3` to `ModulatorType` enum.
- Add `#include <array>` and define `SequencerParams` struct.
- Add `SequencerParams` to the `ModulatorParams` variant.
- Include `SequencerModulatorType.hpp` and register in `ModulationGraph` constructor.

**Dependencies**: None (can be first).

**Parallel-safe**: Yes — prerequisite that unblocks WP2 and WP3.

**Acceptance criteria**:
- Code compiles with `SequencerParams` as a variant alternative.
- Engine links after adding the new type registration (placeholder type header).
- No existing modulator functionality is affected.

---

### WP2: Engine audio-thread modulator (depends on WP1)

**User-visible behavior**: Audio-thread evaluation of step sequences.

**Files assigned**:
- `engine_juce/include/audioapp/modulation/SequencerModulator.hpp` (NEW)
- `engine_juce/src/modulation/SequencerModulator.cpp` (NEW)

**Details**:
- Full `SequencerModulator : IModulator` implementation.
- All four direction modes (Forward, Reverse, PingPong, Random).
- All three shape modes (Hold, Linear, Smooth).
- Smoothing filter (single-pole lowpass).
- Polarity transform.
- Retrigger modes (Free, Sync, OnNote).

**Dependencies**: WP1 (SequencerParams struct must exist).

**Parallel-safe**: Can run in parallel with WP3 (WP2 needs only the struct, WP3 needs only the struct + type enum).

**Acceptance criteria**:
- Tests verify each direction mode produces the correct step sequence.
- Tests verify each shape mode produces correct interpolation.
- Tests verify smoothing converges to target value.
- Tests verify retrigger modes reset state correctly.
- No clicks or artifacts at step boundaries (verified in test render).

---

### WP3: Engine control-thread type (depends on WP1, parallel with WP2)

**User-visible behavior**: Can create and serialize sequencer modulator configurations.

**Files assigned**:
- `engine_juce/include/audioapp/modulation/SequencerModulatorType.hpp` (NEW)

**Details**:
- Full `SequencerModulatorType : IModulatorType` implementation.
- `createDefault()` with 16 steps, all zeros, Forward, Hold, bipolar, quarter-note sync.
- `setParameter()` for all param IDs including `step_N`.
- `createModulator()` instantiates `SequencerModulator`.
- `paramsToVar()` serializes all fields + `step_N` for active steps + `type: "sequencer"`.
- `varToParams()` deserializes all fields + `step_N` from JSON var.

**Dependencies**: WP1 (SequencerParams + enum must exist).

**Parallel-safe**: Yes — parallel with WP2. Needs only the struct definition.

**Acceptance criteria**:
- `createDefault()` returns struct with expected defaults.
- `setParameter` round-trips correctly for all param IDs.
- `paramsToVar` produces valid JSON with all `step_N` fields.
- `varToParams` correctly restores all fields including step values.
- Serialization is lossless for boundary values (stepCount=1, stepCount=32).

---

### WP4: Flutter data model (parallel with WP1 — requires contract stubs only)

**User-visible behavior**: Flutter can parse sequencer modulator data from engine JSON.

**Files assigned**:
- `app_flutter/lib/bridge/project_snapshot.dart`
- `app_flutter/lib/features/device_strip/modulator_types.dart`

**Details**:
- Add `sequencerSteps`, `sequencerDirection`, `sequencerShape`, `stepValues` fields to `LfoSnapshot`.
- Update `modulatorType` getter for `"sequencer"` → 3.
- Add `fromMap` branch for `type == 'sequencer'` that reads all `step_N` properties.
- Add `applyParamUpdate` cases for all sequencer param IDs.
- Add `copyWith` parameters for new fields.
- Add `sequencer = 3` constant and `'SEQ'` label in `ModulatorTypes`.
- Add `sequencerDirectionLabels` and `sequencerShapeLabels`.

**Dependencies**: None (Dart file, no C++ dependency). The `type == 'sequencer'` string must match the engine's `typeId()`. The `step_N` property names must match `paramsToVar` output. These are **contract stubs** defined in this document — no engine code needed first.

**Parallel-safe**: Yes — parallel with WP1. Depends only on the contract, not the implementation.

**Acceptance criteria**:
- `LfoSnapshot.fromMap` with sequencer JSON parses all fields correctly.
- `modulatorType` getter returns 3 for `type == 'sequencer'`.
- `applyParamUpdate` handles all sequencer param IDs.
- Flutter tests pass.

---

### WP5: Flutter properties panel (depends on WP4)

**User-visible behavior**: Full sequencer editing UI in the properties panel.

**Files assigned**:
- `app_flutter/lib/features/device_strip/modulator_properties_panel.dart`
- `app_flutter/lib/features/device_strip/sequencer_step_editor.dart` (NEW)

**Details**:

`_sequencerLayout()` consists of (top to bottom):

1. **Header row**: `'SEQ N'` label + step count pill (e.g. "16 steps").
2. **Expanded step bar editor** (`SequencerStepEditor`):
   - `CustomPainter`-based bar editor.
   - Draws N vertical bars at heights proportional to `stepValues[i]`.
   - Tap/drag on a bar to adjust its value.
   - Visual accent color for active/hovered bar.
   - Current playback step (from ticker) shown as a cursor overlay.
3. **Retrigger mode bar**: Shared `_lfoSegmentBar()` — Free/Sync/OnNote.
4. **Sync divisions bar** (only when retrigger == Sync): Shared `_lfoSyncDivisions()` — 1/1, 1/2, 1/4, 1/8, 1/16.
5. **Polarity toggle**: Shared `_polarityToggle()` — ± / +.
6. **Knob row** (pinned to bottom):
   - Rate knob (compact)
   - Direction cycling knob: cycles 0→1→2→3→0 on tap with label display
   - Shape cycling knob: cycles 0→1→2→0 on tap with label display
   - Smoothing knob (compact)

Direction and shape are displayed as cycling labels (e.g. tap "Fwd" → becomes "Rev" → "P-P" → "Rnd" → "Fwd") rather than dropdowns, to save vertical space.

Double-tap context menu (same pattern as existing `_ModulatorTileState._onDoubleTap`) for batch operations:
- "Clear all steps" (sets all `stepValues` to 0.0)
- "Randomize" (fills steps with random values in [-1, 1])
- "Reverse pattern" (mirrors `stepValues`)

**Dependencies**: WP4 (LfoSnapshot must have sequencer fields).

**Parallel-safe**: No — must be sequential after WP4.

**Acceptance criteria**:
- Panel displays correctly for a sequencer modulator.
- Step bars render at correct heights from `stepValues`.
- Dragging a step bar updates the value via `onUpdate('step_N', value)`.
- Direction cycling knob cycles through all 4 direction modes.
- Shape cycling knob cycles through all 3 shape modes.
- Retrigger, sync divisions, polarity, rate, and smoothing controls work.
- Double-tap context menu operations work.
- Panel fits within available vertical space (header + step bars + retrigger bar + knobs).

---

### WP6: Flutter grid tile + add menu (depends on WP4)

**User-visible behavior**: User can add a sequencer modulator and see it in the grid.

**Files assigned**:
- `app_flutter/lib/features/device_strip/modulation_grid.dart`
- `app_flutter/lib/features/device_strip/sequencer_preview_painter.dart` (NEW)

**Details**:

**Add menu** — add a new `ListTile` in `_showAddMenu`:
```dart
ListTile(
  leading: const Icon(Icons.grid_on, color: Color(0xFFE8A54B)),
  title: const Text('Sequencer', style: TextStyle(color: Colors.white)),
  subtitle: const Text(
    'Multi-step pattern modulator',
    style: TextStyle(color: Colors.white54),
  ),
  onTap: () => Navigator.pop(context, ModulatorTypes.sequencer),
),
```

**Mini step preview tile** — replace the generic tile (or the `ModulatorPreview`) for sequencer type with a custom `SequencerPreviewPainter`:
- Draws tiny vertical bars representing `stepValues`.
- Bars are colored/shaded to show relative magnitudes.
- If a ticker-driven playhead is available, show current step indicator.
- Label "SEQ N" in the corner.

The existing `_ModulatorTile.build()` already has a special case for `randomGenerator`. Add a parallel special case for `modulatorType == 3` that uses `SequencerPreviewPainter`.

**Dependencies**: WP4 (LfoSnapshot must have sequencer fields).

**Parallel-safe**: Can run in parallel with WP5 (different files, both depend only on WP4).

**Acceptance criteria**:
- "Sequencer" option appears in the add modulator bottom sheet.
- Selecting it creates a sequencer modulator.
- Grid tile shows a mini step bar preview.
- Tile displays "SEQ N" label.
- Tapping the tile selects it and opens the sequencer panel.

---

## 7. Test Contract

### C++ engine tests

| Test | File | Covers | Acceptance |
|------|------|--------|------------|
| Directions produce correct sequences | `engine_juce/tests/sequencer_direction_test.cpp` | WP2 | Forward = 0,1,2,... wraps; Reverse = N-1,N-2,... wraps; PingPong alternates; Random uses all indices |
| Shapes produce correct output | `engine_juce/tests/sequencer_shape_test.cpp` | WP2 | Hold = constant step value; Linear = correct ramp endpoints; Smooth = monotonic interpolation |
| Smoothing filter converges | `engine_juce/tests/sequencer_smoothing_test.cpp` | WP2 | Output approaches raw value with time constant proportional to smoothing param |
| Retrigger resets state | `engine_juce/tests/sequencer_retrigger_test.cpp` | WP2 | OnNote resets to step 0; Free keeps running |
| Sync division timing | `engine_juce/tests/sequencer_sync_test.cpp` | WP2 | Step advances at correct beat intervals for each division |
| Serialization round-trip | `engine_juce/tests/sequencer_serialization_test.cpp` | WP3 | paramsToVar → varToParams returns identical struct for all fields including step values |
| Set parameter by ID | `engine_juce/tests/sequencer_set_param_test.cpp` | WP3 | All param IDs set correct fields; invalid param returns false; step_N clamps to valid range |
| Step count boundary | `engine_juce/tests/sequencer_step_count_test.cpp` | WP2, WP3 | stepCount=1 produces single repeating step; stepCount=32 uses all 32 values |
| Type registration | `engine_juce/tests/sequencer_registration_test.cpp` | WP1 | ModulationGraph has 4 types; typeId() returns "sequencer"; modulatorTypeValue() returns 3 |

### Flutter tests

| Test | File | Covers | Acceptance |
|------|------|--------|------------|
| Parse sequencer snapshot | `app_flutter/test/bridge/sequencer_snapshot_test.dart` | WP4 | LfoSnapshot.fromMap with sequencer JSON reads all fields |
| Parameter update routing | `app_flutter/test/bridge/sequencer_param_test.dart` | WP4 | applyParamUpdate for steps, direction, shape, step_N |
| ModulatorTypes constant | `app_flutter/test/features/sequencer_constants_test.dart` | WP4 | sequencer = 3, labelFor(3) = 'SEQ' |
| Add menu includes sequencer | `app_flutter/test/features/sequencer_add_menu_test.dart` | WP6 | Bottom sheet has "Sequencer" option |
| Grid tile renders for sequencer | `app_flutter/test/features/sequencer_grid_test.dart` | WP6 | Sequencer tile shows mini preview and label |
| Step editor renders and responds to drag | `app_flutter/test/features/sequencer_editor_test.dart` | WP5 | Step bars render; drag updates value |
| Sequencer panel layout | `app_flutter/test/features/sequencer_panel_test.dart` | WP5 | Panel renders header, step bars, retrigger bar, knobs row |

---

## 8. Integration Plan

### Recommended implementation order

```
WP1 (engine params + enum + registration)
  ├── WP2 (engine audio-thread modulator) — parallel with WP3
  ├── WP3 (engine control-thread type) — parallel with WP2
  └── WP4 (Flutter data model) — parallel with WP1
        ├── WP5 (Flutter properties panel) — after WP4
        └── WP6 (Flutter grid tile + add menu) — after WP4, parallel with WP5
```

### Packages that can run in parallel

- **WP2 + WP3**: Both depend on WP1 only; need only `SequencerParams` struct and `ModulatorType::Sequencer` enum. They write disjoint files.
- **WP5 + WP6**: Both depend on WP4 only; they write disjoint files (`modulator_properties_panel.dart` vs `modulation_grid.dart` plus their respective new widget files).
- **WP1 + WP4**: WP1 is C++, WP4 is Dart. They depend only on shared contract names (typeId = `"sequencer"`, enum value = 3, param IDs), not on each other's code.

### Packages that must be sequential

- **WP4 → WP5, WP4 → WP6**: Flutter code cannot compile without the LfoSnapshot fields. WP5 and WP6 can, however, run in parallel with each other after WP4 is committed.

### Shared files requiring care

| File | Risk | Mitigation |
|------|------|------------|
| `ModulatorParams.hpp` | Adding to variant changes variant size | No index-based variant access exists; all code uses `std::get<ConcreteType>` |
| `ModulationGraph.cpp` | Registration order must match enum values | Append SequencerModulatorType last (index 3 matches `ModulatorType::Sequencer = 3`) |
| `project_snapshot.dart` | Multiple WP depend on it | WP4 must be committed first; WP5/WP6 branch from WP4 |
| `modulator_properties_panel.dart` | Layout branching in `build()` | WP5 adds `_sequencerLayout` path without modifying existing branches |
| `modulation_grid.dart` | Add menu and tile logic | WP6 adds one ListTile and one tile branch; existing tile code untouched |

### Contract gaps / risks

1. **Step value serialization size**: Emitting up to 32 `step_N` properties in JSON may increase snapshot size. At ~20 bytes per property = ~640 bytes max for step values, this is negligible.

2. **`updateParams` atomicity**: The `SequencerParams` struct is ~148 bytes (4 + 4 + 4 + 4 + 4 + 4 + 4 + 4 + 32*4 = 148 bytes). The control thread writes this under exclusive lock. The audio thread reads it with no lock. This is safe because:
   - All scalar fields are 32-bit aligned (naturally atomic reads on ARM64 and x86_64).
   - The `std::array<float, 32>` is 128 bytes. On ARM64, a 128-byte load may not be atomic. However, the audio thread reads step values one at a time by index — the control thread cannot be in the middle of writing the struct while the audio thread reads, because `updateParams()` is called under the exclusive lock held by the control thread, and the audio thread never calls `updateParams()`. The only risk is a torn read of a single `float` element, which is not possible on ARM64 for 32-bit aligned floats.

3. **`stepValues` size change on `stepCount` update**: When the user changes `stepCount` from 16 to 8, the array elements beyond index 7 are still present in the struct (they're part of the fixed `std::array<float, 32>`). They're simply not used. This is correct by design — the array is always 32 elements; `stepCount` controls the logical active range.

4. **Dart `stepValues` list synchronization**: When `stepCount` changes on the Flutter side, the `stepValues` list should be truncated or padded. The `fromMap` branch reads `stepCount` properties from JSON. If the user changes step count via the UI, the `applyParamUpdate` for `"steps"` should also adjust `stepValues` (truncate or pad with zeros).

5. **PingPong starting direction**: At `reset()`, PingPong starts with `pingPongDir = 1` (incrementing). This is the most intuitive behavior — first step advances forward.

6. **Random direction determinism**: The `XorShiftRng` from `RandomGeneratorModulator.hpp` should be reused (or a separate instance embedded in `SequencerModulator`). The shuffle is deterministic given the same seed, which is important for reproducible playback.

7. **Interpolation shapes and step boundaries**: For Linear and Smooth shapes, the "next step" index at the last step wraps to step 0 (for Forward) or stays at the last step value (for end-of-cycle). PingPong reverses direction at boundaries, so "next step" at the end is the previous step.

---

## 9. Error Model

| Error condition | Behavior | Location |
|-----------------|----------|----------|
| `stepCount` = 0 or negative | Clamped to 1 in `setParameter` | `SequencerModulatorType::setParameter` |
| `stepCount` > 32 | Clamped to 32 | `SequencerModulatorType::setParameter` |
| Invalid direction value (outside 0–3) | Clamped to 0 | `SequencerModulatorType::setParameter` |
| Invalid shape value (outside 0–2) | Clamped to 0 | `SequencerModulatorType::setParameter` |
| Invalid `step_N` index (N < 0 or N > 31) | `setParameter` returns false | `SequencerModulatorType::setParameter` |
| Missing `type` field in `varToParams` | Falls through to default construct | `SequencerModulatorType::varToParams` |
| `step_N` key missing in JSON for some N < stepCount | Defaults to 0.0 | `SequencerModulatorType::varToParams` |
| Division by zero in rate calculation | Rate clamped to minimum 0.05 Hz | `SequencerModulator::rateToHz` |

---

## 10. Manual Verification Steps

1. **Add sequencer modulator**: Open device strip → tap "+" in modulation grid → select "Sequencer" → a new SEQ tile appears in the grid.
2. **Edit step values**: Tap SEQ tile to open properties panel → drag step bars up/down → values update in real-time.
3. **Change step count**: Tap step count pill → count changes → step editor shows correct number of bars.
4. **Change direction**: Tap direction cycling knob → observe Forward/Reverse/PingPong/Random behavior in preview.
5. **Change shape**: Tap shape cycling knob → observe Hold/Linear/Smooth interpolation in preview.
6. **Sync to tempo**: Set retrigger to Sync → select quarter-note → sequencer advances one step per beat.
7. **Free running**: Set retrigger to Free → adjust Rate knob → sequencer advances at independent speed.
8. **Smoothing**: Turn up Smoothing knob → stepped output becomes rounded/smeared.
9. **Polarity**: Toggle polarity → output switches between bipolar and unipolar.
10. **Save and reload**: Save project → close → reopen → sequencer parameters are preserved including all step values.
11. **Audio artifacts**: During playback, editing step values or parameters should produce no clicks or pops.