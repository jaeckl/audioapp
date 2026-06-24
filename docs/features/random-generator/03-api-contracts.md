# API / Data Contracts: Random Generator Modulator

## C++ Interface: `RandomGeneratorModulatorType`

```cpp
class RandomGeneratorModulatorType : public IModulatorType {
    std::string typeId() const override;                    // returns "random_generator"
    int modulatorTypeValue() const override;                // returns 2
    ModulatorParams createDefault() const override;         // returns RandomGeneratorParams{0.5f, 0.0f, 1, 0}
    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override;
    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override;
    juce::var paramsToVar(const ModulatorParams& params) const override;
    ModulatorParams varToParams(const juce::var& obj) const override;
};
```

## C++ Struct: `RandomGeneratorParams`

```cpp
struct RandomGeneratorParams {
    float rate = 0.5f;        // [0, 1] — mapped to speed
    float smoothing = 0.0f;   // [0, 1] — 0=instant steps, 1=full slew
    int retrigger = 1;          // 0=Free, 1=Sync, 2=OnNote
    int polarity = 0;           // 0=bipolar, 1=unipolar
};
```

Added to `ModulatorParams` variant:
```cpp
using ModulatorParams = std::variant<LfoParams, EnvelopeParams, RandomGeneratorParams>;
```

## RandomGeneratorParams::setParameter API

| paramId | Type | Range | Clamp | Behavior |
|---------|------|-------|-------|----------|
| `"rate"` | float | [0, 1] | `std::clamp(value, 0.0f, 1.0f)` | |
| `"smoothing"` | float | [0, 1] | `std::clamp(value, 0.0f, 1.0f)` | |
| `"retrigger"` | int | [0, 2] | `std::clamp(static_cast<int>(value), 0, 2)` | |
| `"polarity"` | int | [0, 1] | `std::clamp(static_cast<int>(value), 0, 1)` | Only 0/1 (no unipolar-neg) |

Return: `true` if handled, `false` for unknown paramId.

## C++ Interface: `RandomGeneratorModulator` (implements `IModulator`)

```cpp
class RandomGeneratorModulator : public IModulator {
public:
    explicit RandomGeneratorModulator(const RandomGeneratorParams& params);

    void reset() noexcept override;
    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;
    int modulatorType() const noexcept override;  // returns 2

private:
    RandomGeneratorParams params_;
    struct Runtime {
        float currentValue = 0.0f;           // current random value (before smoothing)
        float smoothedValue = 0.0f;          // output after slew
        double lastSampleTime = 0.0;          // time of last random sample
        double nextSampleTime = 0.0;          // time of next random sample
        uint32_t lastRetriggerGeneration = std::numeric_limits<uint32_t>::max();
    };
    Runtime rt_;
};
```

### `evaluate()` Behavior

1. **Retrigger = OnNote**: When `retriggerGeneration != rt_.lastRetriggerGeneration`, reset internal clock and draw a new random value immediately, set `lastRetriggerGeneration`.
2. **Retrigger = Sync**: Use `playheadBeat` to determine phase. Rate maps to beat divisions (same as LFO: `lfoSyncBeats` + `lfoRateToSpeedMult`). At each division boundary, draw new random value.
3. **Retrigger = Free**: Use `secondsWithinBlock` as elapsed time. Rate maps to Hz via `lfoRateToHz`. At each rate period boundary, draw new random value.
4. **Smoothing**: When `smoothing > 0`, linearly interpolate from previous value to new value over the rate period. `smoothing = 1` means the slewed value reaches the target exactly at the next sample point. `smoothing = 0` means instant step.
5. **Polarity**: If unipolar, map from [-1, 1] to [0, 1] via `value * 0.5f + 0.5f`.

### Random Number Generation

- Each `RandomGeneratorModulator` instance creates its own `thread_local static` or member `std::mt19937` seeded once in constructor.
- On each sample event, draw `std::uniform_real_distribution<float>(-1.0f, 1.0f)`.
- Real-time safe: no allocations after construction.

## JSON Serialization Shape

```json
{
  "id": 5,
  "type": "random_generator",
  "rate": 0.5,
  "smoothing": 0.3,
  "retrigger": 1,
  "polarity": 0
}
```

## Flutter: `LfoSnapshot` Additional Fields

```dart
class LfoSnapshot {
  // Existing fields...
  int modulatorType;       // already exists
  double rate;             // already exists (used by LFO/envelope params)
  int retrigger;           // already exists
  int polarity;            // already exists (was 0/1/2 for LFO, 0/1 for random)
  double smoothing;        // NEW FIELD
  // Envelope-specific fields (attack, decay, sustain, release...) — no change
}
```

### `applyParamUpdate()` for Random Generator

```dart
// Inside LfoSnapshot.applyParamUpdate():
case ModulatorTypes.randomGenerator:
  switch (param) {
    case 'rate': rate = value; break;
    case 'smoothing': smoothing = value; break;
    case 'retrigger': retrigger = value.toInt(); break;
    case 'polarity': polarity = value.toInt(); break;
  }
```

### `copyWith()` for Random Generator

```dart
// Include smoothing field:
copyWith({..., double? smoothing})
```

## Flutter: `ModulatorMath.preview()` for Random Generator

```dart
static List<double> randomGeneratorPreview({
  required double rate,
  required double smoothing,
  required int retrigger,
  required double durationBeats,
  required int bpm,
  required int sampleCount,
}) {
  // Generate stepped random values at rate-specified intervals
  // Apply smoothing (linear slew between steps)
  // Returns sampleCount values in [-1, 1]
}
```

The preview function is stateless (no persistence between redraws) but should use a deterministic seed derived from the modulator ID or a fixed seed so the preview doesn't jump on every redraw — OR accept that it will produce different curves on each call (acceptable for a preview since the actual audio-thread random is independent and uncorrelated).

**Recommendation**: Accept non-deterministic preview (changes each frame). This actually looks more alive in the UI. The real engine random is on the audio thread and is independent.

## Bridge API (No Changes Needed)

| Bridge Method | Args | Works For Random? |
|--------------|------|------------------|
| `createLfo` | `{modulatorType: 2}` | Yes — just pass type index 2 |
| `updateLfoParam` | `{lfoId: N, param: "rate"|"smoothing"|"retrigger"|"polarity", value: V}` | Yes — generic param dispatch |

The `createLfo` method already accepts a `modulatorType` int. The `updateLfoParam` method already dispatches to the type's `setParameter`. The bridge is fully generic — no changes required.

## ModulationGraph::createLfo Changes

The clamp in `createLfo` must change from:
```cpp
const int typeIndex = std::clamp(modulatorType, 0, 1);
```
to:
```cpp
const int typeIndex = std::clamp(modulatorType, 0, static_cast<int>(modulatorTypes_.size()) - 1);
```

This makes the code self-adapting to any new modulator type added to the constructor.