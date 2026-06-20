# API and Data Contracts

## 3.1 IDeviceType Interface Extension (Optional — Not Required for Phase 1)

If we choose to add serialization to `IDeviceType` (vs free-function dispatch):

```cpp
// Add to IDeviceType.hpp:
virtual juce::var toVar(const DeviceState& state) const;
virtual DeviceState fromVar(const juce::var& value) const;
```

**Recommendation:** Do NOT extend IDeviceType. Instead use a free-function
dispatch in ProjectJson.cpp that maps `device.type` string → per-type serializer.
This is less invasive and leaves the existing control-thread interface untouched.

---

## 3.2 Per-Device Serializer Dispatch

### `deviceToVar` (remains in ProjectJson.cpp, now dispatches):

```cpp
juce::var deviceToVar(const DeviceState& device) {
    if (device.type == "simple_oscillator")   return oscillatorToVar(device);
    if (device.type == "simple_sampler")      return samplerToVar(device);
    if (device.type == "subtractive_synth")   return subtractiveSynthToVar(device);
    if (device.type == "bass_synth")          return bassSynthToVar(device);
    if (device.type == "kick_generator")      return kickGeneratorToVar(device);
    if (device.type == "snare_generator")     return snareGeneratorToVar(device);
    if (device.type == "clap_generator")      return clapGeneratorToVar(device);
    if (device.type == "cymbal_generator")    return cymbalGeneratorToVar(device);
    if (device.type == "crash_generator")     return crashGeneratorToVar(device);
    if (device.type == "gate")                return gateToVar(device);
    if (device.type == "compressor")          return compressorToVar(device);
    if (device.type == "expander")            return expanderToVar(device);
    if (device.type == "limiter")             return limiterToVar(device);
    if (device.type == "track_gain")          return trackGainToVar(device);
    // fallback: serialize id + type + known fields
    return fallbackDeviceToVar(device);
}
```

### `deviceFromVar` (remains in ProjectJson.cpp, now dispatches):

```cpp
DeviceState deviceFromVar(const juce::var& value) {
    // Read type field, call per-type deserializer
    const auto type = varToString(object->getProperty("type"));
    if (type == "simple_oscillator")   return oscillatorFromVar(value);
    if (type == "simple_sampler")      return samplerFromVar(value);
    // ... etc
    return fallbackDeviceFromVar(value);
}
```

---

## 3.3 Per-Device Serializer Contract

### Location: `engine_juce/include/audioapp/devices/serialization/OscillatorSerializer.hpp`

```cpp
#pragma once
#include "audioapp/DeviceState.hpp"
#include <juce_core/juce_core.h>

namespace audioapp {

/// Serialize oscillator-specific fields from DeviceState to juce::var.
/// Only reads fields relevant to "simple_oscillator" type.
juce::var oscillatorToVar(const DeviceState& device);

/// Deserialize oscillator fields from juce::var to DeviceState.
/// Only writes fields relevant to "simple_oscillator" type.
DeviceState oscillatorFromVar(const juce::var& value);

} // namespace audioapp
```

Each per-device serializer follows the same pattern.

### Key contract: each serializer ONLY touches its own fields.

- `oscillatorToVar` reads: `device.id`, `device.type`, `device.gain`, `device.pan`,
  `device.bypassed`, `device.frequencyHz`
- `samplerToVar` reads: `device.id`, `device.type`, `device.gain`, `device.pan`,
  `device.sampleId`, `device.attack`, `device.decay`, `device.sustain`,
  `device.release`, `device.filterCutoff`, `device.filterQ`, `device.filterMode`,
  `device.trimStartSec`, `device.trimEndSec`, `device.regionStartSec`,
  `device.regionEndSec`, `device.rootPitch`, `device.rootFineTune`, `device.playbackMode`
- `trackGainToVar` reads: `device.id`, `device.type`, `device.gain` (only!)
- etc.

### Legacy compatibility

Each deserializer MUST preserve existing fallback logic for renamed fields.
For example, `oscillatorFromVar` checks `hasProperty("osc1Shape")` first,
but falls back to `osc1Wave` → `osc1Shape` conversion.
These legacy fallbacks must be documented in comments in each serializer.

---

## 3.4 Per-Device Process Contracts

### Process function signature convention:

```cpp
namespace audioapp {

/// Process one oscillator device node for a block of frames.
/// @param scratch     Scratch buffer (pre-zeroed, framesToProcess length)
/// @param frames      Number of frames to process
/// @param sampleRate  Current sample rate in Hz
/// @param oscillatorPhase  Phase state (mutated across calls)
/// @param params      OscillatorParams for this block
/// @param notes       Active MIDI notes for this track
/// @param noteCount   Number of active MIDI notes
/// @param playheadBeat  Current playhead position in beats
/// @param needsSubBlocks  Whether sub-block automation/modulation is required
/// @param automationClips  Automation clips (may be nullptr)
/// @param automationClipCount  Number of automation clips
/// @param lfoValues   LFO buffer (lfoCount × frames, interleaved)
/// @param lfoCount    Number of LFOs
/// @param modEdges    Modulation edges (may be nullptr)
/// @param modEdgeCount  Number of modulation edges
/// @param perFrameGain  Pre-computed per-frame gain (including gain automation/mod)
/// @param perFramePan   Pre-computed per-frame pan
/// @param trackLeft   Track output left channel accumulator
/// @param trackRight  Track output right channel accumulator
void processOscillatorNode(
    float* scratch, int frames, double sampleRate,
    float& oscillatorPhase, const OscillatorParams& params,
    const MidiPlaybackNote* notes, int noteCount,
    double playheadBeat, bool needsSubBlocks,
    const AutomationClipPlayback* automationClips, int automationClipCount,
    const float* lfoValues, int lfoCount,
    const ModulationEdgePlayback* modEdges, int modEdgeCount,
    const float* perFrameGain, const float* perFramePan,
    float* trackLeft, float* trackRight) noexcept;

} // namespace audioapp
```

Each device kind gets its own `process*Node` function. The exact parameter
list varies by device (e.g., sampler needs `BiquadState*`, subtractive synth
needs `SubtractiveSynthRuntime*`, etc.).

---

## 3.5 Bridge Utility Contracts

### Location: `engine_juce/include/audioapp/BridgeUtil.hpp`

```cpp
#pragma once
#include <string>
#include <vector>
#include "audioapp/ProjectEngine.hpp"  // for SubtractivePresetArgs
#include "audioapp/ProjectJson.hpp"    // for SubtractivePresetArgs, MidiNoteState etc.

namespace audioapp::bridge_util {

// JSON argument extraction
std::string jsonGetStringArg(const std::string& argumentsJson, const std::string& key);
double       jsonGetNumberArg(const std::string& argumentsJson, const std::string& key, double fallback = 0.0);
bool         jsonGetBoolArg(const std::string& argumentsJson, const std::string& key, bool fallback = false);

// Bridge response builders
std::string buildBridgeOkWithSnapshot(const std::string& snapshotJson);
std::string buildBridgeOkTransportState(const TransportStateSnapshot& transport);
std::string buildBridgeOkWithPath(const std::string& path);
std::string buildBridgeOkWithMessage(const std::string& message);
std::string buildBridgeError(const std::string& errorCode);

// Argument parsers
std::vector<MidiNoteState>        parseMidiNotesFromArgs(const std::string& argumentsJson);
std::vector<AutomationPointState> parseAutomationPointsFromArgs(const std::string& argumentsJson);
bool                             parseSubtractivePresetArgs(const std::string& argumentsJson,
                                                             SubtractivePresetArgs& out);

} // namespace audioapp::bridge_util
```

### Header dependency changes:

- `native_bridge/src/BridgeHost.cpp` — changes `#include "audioapp/ProjectJson.hpp"` to
  `#include "audioapp/BridgeUtil.hpp"`
- `engine_juce/src/EngineHost_commands.cpp` — same include change
- `engine_juce/include/audioapp/ProjectJson.hpp` — removes the above declarations

---

## 3.6 LFO Math Declaration Move

### Current (in `ProjectJson.hpp`):

```cpp
float lfoEvaluate(LfoWaveform waveform, float phase) noexcept;
double lfoSyncBeats(int syncDivision) noexcept;
float modulatorApplyPolarity(float value, int polarity) noexcept;
float modulatorEvaluateSynced(const LfoState& state, double playheadBeat, int bpm, double frameSeconds) noexcept;
float modulatorEvaluateOnNote(const LfoState& state, double frameSeconds, uint32_t retriggerGeneration,
                              uint32_t& lastRetriggerGeneration, float& envelopeLevel,
                              int& envelopeStage, double& segStartSeconds) noexcept;
```

### Target (in `LfoTypes.hpp`):

```cpp
// Add to existing LfoTypes.hpp after LfoState/ModulationEdge structs:

/// LFO waveform evaluation (realtime-safe).
float lfoEvaluate(LfoWaveform waveform, float phase) noexcept;

/// BPM-sync beat length for a sync division (realtime-safe).
double lfoSyncBeats(int syncDivision) noexcept;

/// Apply polarity modifier to a modulation value (realtime-safe).
float modulatorApplyPolarity(float value, int polarity) noexcept;

/// Evaluate a synced modulator (LFO/ADSR) at a given playhead position (realtime-safe).
float modulatorEvaluateSynced(const LfoState& state, double playheadBeat, int bpm, double frameSeconds) noexcept;

/// Evaluate a per-note modulator at a given frame time (realtime-safe).
float modulatorEvaluateOnNote(const LfoState& state, double frameSeconds, uint32_t retriggerGeneration,
                              uint32_t& lastRetriggerGeneration, float& envelopeLevel,
                              int& envelopeStage, double& segStartSeconds) noexcept;
```
