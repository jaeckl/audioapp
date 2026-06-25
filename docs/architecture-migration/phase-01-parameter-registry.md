# Phase 1 — Parameter Registry

> **Goal:** Replace `IDeviceType::setParameter(string, float)` string-switch chains with an integer-based parameter registry — single source of truth for all device parameter metadata.

## Current State

Every device type has a hand-rolled if-else chain like this (`SubtractiveSynthDeviceType`):

```cpp
if (parameterId == "filterCutoff" || parameterId == "filterQ" || ...) {
    if (parameterId == "filterCutoff") {
        instance.filterCutoff = clamped;
    } else if (parameterId == "filterQ") {
        instance.filterQ = clamped;
    } ...
}
```

This repeats in `setParameter()`, `slotToVar()`, `varToSlot()`, `modulatableParams()`. There are **21 device types** × ~10-40 params each = **200+ runtime string comparisons** per param set, and the param definitions are scattered across 4+ functions per type.

## Design

### A. Parameter Definition

A single struct captures everything about a parameter in one place:

```cpp
// engine_juce/include/audioapp/params/ParamDef.hpp
namespace audioapp::params {

/// Uniquely identifies a parameter across all device types.
/// Layout: (deviceTypeIndex << 16) | paramIndex
using ParamId = uint32_t;

struct ParamDef {
    ParamId id;
    std::string_view name;        // human-readable, also used as JSON key
    float defaultValue;
    float minValue;
    float maxValue;
    std::string_view unit;        // "Hz", "dB", "s", "%", "" etc.
    std::string_view displayName; // UI label
    bool isModulatable = false;
};

} // namespace audioapp::params
```

### B. Per-Device Parameter Table

Each device type declares its parameters as a compile-time table:

```cpp
// SubtractiveSynthDeviceType.cpp (or a dedicated SubtractiveSynthParams.hpp)
namespace audioapp::params::subtractive_synth {

inline constexpr int kTypeIndex = 4; // assigned by registry order

enum Id {
    AmpAttack    = (kTypeIndex << 16) | 0,
    AmpDecay     = (kTypeIndex << 16) | 1,
    AmpSustain   = (kTypeIndex << 16) | 2,
    AmpRelease   = (kTypeIndex << 16) | 3,
    FilterCutoff = (kTypeIndex << 16) | 4,
    FilterQ      = (kTypeIndex << 16) | 5,
    // ... all ~40 params
};

inline constexpr ParamDef kParams[] = {
    {AmpAttack,    "ampAttack",    0.5f,  0.0f, 1.0f, "s",  "Amp Attack",    true},
    {AmpDecay,     "ampDecay",     0.22f, 0.0f, 1.0f, "s",  "Amp Decay",     true},
    {AmpSustain,   "ampSustain",   0.65f, 0.0f, 1.0f, "",   "Amp Sustain",   true},
    {AmpRelease,   "ampRelease",   0.28f, 0.0f, 1.0f, "s",  "Amp Release",   true},
    {FilterCutoff, "filterCutoff", 0.5f,  0.0f, 1.0f, "",   "Filter Cutoff", true},
    // ...
};

} // namespace audioapp::params::subtractive_synth
```

### C. Registry Object

```cpp
// engine_juce/include/audioapp/params/ParamRegistry.hpp
namespace audioapp::params {

class ParamRegistry {
public:
    void registerDeviceParams(std::string_view deviceTypeId,
                              std::span<const ParamDef> params,
                              std::span<const ParamId> modulatableIds);

    const ParamDef* find(ParamId id) const;
    const ParamDef* findByName(std::string_view deviceTypeId,
                                std::string_view name) const;
    std::string_view nameForJson(ParamId id) const;  // "ampAttack"
    ParamId idFromJson(std::string_view deviceTypeId,
                        std::string_view jsonName) const; // AmpAttack

    std::span<const ParamDef> allForDevice(std::string_view deviceTypeId) const;
    std::span<const ParamId> modulatableForDevice(std::string_view deviceTypeId) const;

private:
    // Flat arrays keyed by (deviceTypeIndex → param array)
    std::vector<DeviceParamBlock> blocks_;
};

} // namespace audioapp::params
```

The registry is a **singleton per DeviceRegistry** (or part of it). It maps:
- `ParamId` (int) → `ParamDef` (O(1) via array offset)
- string name → `ParamId` (hash map, for JSON deserialization only)

### D. New IDeviceType::setParameter

```cpp
DeviceParameterResult SubtractiveSynthDeviceType::setParameter(
    DeviceSlot& slot, std::string_view parameterId, float value) const
{
    using namespace params::subtractive_synth;
    DeviceParameterResult result;

    // Try strip params first (gain/pan/bypass — handled by base infrastructure)
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    // Fast int path: registry maps string → ParamId
    auto& instance = std::get<SubtractiveSynthParams>(slot.config.instance);
    const ParamId pid = registry_->idFromJson(typeId(), parameterId);
    switch (pid) {
    case AmpAttack:    instance.ampAttack    = clampAndReturn(pid, value); break;
    case AmpDecay:     instance.ampDecay     = clampAndReturn(pid, value); break;
    case AmpSustain:   instance.ampSustain   = clampAndReturn(pid, value); break;
    case AmpRelease:   instance.ampRelease   = clampAndReturn(pid, value); break;
    case FilterCutoff: instance.filterCutoff = clampAndReturn(pid, value); break;
    // ... compile-time switch, no string compares
    default: result.handled = false; return result;
    }
    result.handled = true;
    return result;
}
```

### E. Eliminated Redundancy

`modulatableParams()` becomes a one-liner:

```cpp
std::vector<std::string_view> SubtractiveSynthDeviceType::modulatableParams() const {
    return registry_->modulatableForDevice(typeId())
        | std::views::transform([&](ParamId id) { return registry_->find(id)->name; })
        | std::ranges::to<std::vector>();
}
```

`slotToVar()` and `varToSlot()` iterate the param table generically:

```cpp
juce::var SubtractiveSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& inst = std::get<SubtractiveSynthParams>(slot.config.instance);
    auto* obj = new juce::DynamicObject();
    // Generic serializer: iterate param defs, read via visitor
    registry_->forEachParam(typeId(), [&](const ParamDef& def) {
        obj->setProperty(juce::String(def.name), static_cast<double>(readParam(inst, def.id)));
    });
    return juce::var(obj);
}
```

The `readParam()` / `writeParam()` functions use a single switch on `ParamId` extracted from the param table — **one switch instead of N string compares in each of 3 functions**.

## Changes Required

| File | Change |
|------|--------|
| **NEW** `engine_juce/include/audioapp/params/ParamDef.hpp` | `ParamId` typedef, `ParamDef` struct |
| **NEW** `engine_juce/include/audioapp/params/ParamRegistry.hpp` | Registry interface |
| **NEW** `engine_juce/src/params/ParamRegistry.cpp` | Registry implementation |
| **NEW** `engine_juce/include/audioapp/params/SubtractiveSynthParams.hpp` | Parameter enum + table |
| **NEW** `engine_juce/include/audioapp/params/...*Params.hpp` | One per device type (21 files) |
| **MODIFY** `IDeviceType.hpp` | Add `registry()` accessor or pass registry to constructor |
| **MODIFY** `DeviceRegistry.hpp` | Own a `ParamRegistry` instance |
| **MODIFY** All `*DeviceType::setParameter()` | Switch from string-if to int-switch |
| **MODIFY** All `*DeviceType::slotToVar()` | Use generic param-table-based serialization |
| **MODIFY** All `*DeviceType::varToSlot()` | Use generic param-table-based deserialization |
| **MODIFY** All `*DeviceType::modulatableParams()` | Delegate to registry |
| **MODIFY** `DeviceStripParams.hpp` | Keep strip params (gain/pan/bypass) as-is — they are cross-cutting |

## Test Strategy

1. **ParamDef table test:** Verify every param has a unique `ParamId`, correct ranges, defaults match existing behavior
2. **Round-trip test:** Write all params via `setParameter(string)`, read via `slotToVar()`, verify JSON keys match param names
3. **Performance test:** Measure 1000 `setParameter` calls — verify at least 10× improvement over string-chain
4. **Regression:** All existing device round-trip tests must pass unchanged

## Effort Estimate

| Item | Days |
|------|------|
| `ParamDef` + `ParamRegistry` skeleton | 1 |
| Migrate 1 device type (pilot: TrackGain) | 0.5 |
| Migrate remaining 20 device types | 5 |
| Update serialization helpers | 2 |
| Tests | 2 |
| **Total** | **10.5** |

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Breaking parameter names in JSON (Flutter breaks) | Low | Round-trip tests verify JSON keys are unchanged |
| `ParamId` collision across device types | Low | Type index prefix ensures uniqueness |
| Some device types have unusual param patterns | Medium | Pilot with TrackGain first, handle edge cases incrementally |