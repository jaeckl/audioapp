# Frequency FX Suite — Architecture

## Architecture Decision

The three frequency FX devices follow the same pattern as dynamics devices (Gate/Compressor/Expander/Limiter):

- **IDeviceType subclass** per device (like `CompressorDeviceType`)
- **Instance struct** with control-thread parameters (like `CompressorInstance`)
- **Params struct** for audio-thread use (like `CompressorParams`)
- **Runtime struct** for per-block state persistence (like `DynamicsRuntime`)
- **Processing functions** operate on stereo blocks in-place
- **DeviceNodeKind** enum entries
- **DeviceVariantParams** variant entries
- **Switch cases** in `processDeviceChain()` body
- **applyModulation() overloads** for modulation
- **DynamicsInputPanel + DynamicsOutputPanel** in chrome

## Module Boundaries

```
engine_juce/
├── include/audioapp/
│   ├── FrequencyFxProcessor.hpp      ← params, runtime, processing functions
│   └── devices/
│       ├── instances/
│       │   └── FrequencyFxInstance.hpp ← instance structs
│       ├── FilterDeviceType.hpp
│       ├── FourBandEqDeviceType.hpp
│       └── FrequencyShifterDeviceType.hpp
├── src/
│   ├── FrequencyFxProcessor.cpp        ← processing implementation (juce::dsp)
│   └── devices/
│       ├── FilterDeviceType.cpp
│       ├── FourBandEqDeviceType.cpp
│       └── FrequencyShifterDeviceType.cpp

app_flutter/lib/features/device_strip/
├── frequency_fx_panels.dart            ← FilterPanel, FourBandEqPanel, FreqShifterPanel
├── filter_preview.dart                 ← Filter curve custom painter
└── eq_preview.dart                     ← EQ curve custom painter
```

## Threading/Async Boundaries

- **Control thread**: IDeviceType methods (setParameter, slotToVar, createDefault, buildPlaybackNode)
- **Audio thread**: processing functions in FrequencyFxProcessor.cpp, called from DeviceChain.cpp
- No JSON parsing on audio thread (parse on control thread, apply snapshot)
- Runtime structs are per-block state; one per device instance, indexed by device index

## Threading Model for Processing

Each frequency FX device processes the stereo buffer in-place, same pattern as dynamics:

```cpp
case DeviceNodeKind::Filter: {
    auto p = std::get<FilterParams>(modulatedParams);
    FilterRuntime localRuntime{};
    auto& runtime = filterRuntimes != nullptr ? filterRuntimes[deviceIndex] : localRuntime;
    processFilterStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
    // gain/pan applied by outer loop
    break;
}
```

## Error Model

- Parameter validation via `std::clamp` (normalized 0-1) or `juce::jlimit` (real-world ranges)
- Runtime structs are default-constructed as local fallback if nullptr is passed
- Processing functions are noexcept
- JSON deserialization falls back to defaults on missing keys

## Persistence Model

Each device follows the existing slotToVar/varToSlot JSON pattern used by dynamics devices:

```json
{
    "id": "uuid",
    "type": "filter",
    "parameters": {
        "gain": 1.0, "pan": 0.5, "bypass": 0.0,
        "ffxCutoff": 0.6, "ffxResonance": 0.3, "ffxFilterMode": 0.0
    },
    "meters": { "gainReductionDb": 0.0, "inputLevel": 0.0 }
}
```

## UI/State Synchronization

- DeviceSnapshot's flat fields are populated from JSON parameters
- onDeviceParameterChanged callback writes through to the engine
- Meter data (inputLevel) published from audio thread via DeviceMeterAtomic array
- Filter preview and EQ preview are rendered as CustomPainter widgets on the UI thread