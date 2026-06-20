#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace audioapp {

struct AutomationPointPlayback {
    float beat = 0.0f;
    float value = 0.0f;
};

constexpr int kMaxAutomationPlaybackPoints = 256;

// -----------------------------------------------------------------------
// Per-device parameter enums — each is a uint16_t, local to its device.
// The numeric values are per-enum (they can overlap between devices).
// -----------------------------------------------------------------------

enum class CommonParam : uint16_t {
    Gain = 0,
    Pan = 1,
    Bypass = 2,
};

enum class OscillatorParam : uint16_t {
    Frequency = 0,
};

enum class SamplerParam : uint16_t {
    FilterCutoff = 0,
    FilterQ = 1,
    Attack = 2,
    Decay = 3,
    Sustain = 4,
    Release = 5,
    RootPitch = 6,
    RootFineTune = 7,
    FilterEnvAmount = 8,
    FilterAttack = 9,
    FilterDecay = 10,
    FilterSustain = 11,
    FilterRelease = 12,
};

enum class SubtractiveParam : uint16_t {
    FilterCutoff = 0,
    FilterQ = 1,
    FilterMode = 2,
    AmpAttack = 3,
    AmpDecay = 4,
    AmpSustain = 5,
    AmpRelease = 6,
    Osc1Shape = 7,
    Osc2Shape = 8,
    Osc1Octave = 9,
    Osc1Semi = 10,
    Osc1Detune = 11,
    Osc2Octave = 12,
    Osc2Semi = 13,
    Osc2Detune = 14,
    OscMix = 15,
    OscMixMode = 16,
    Osc1Sync = 17,
    Osc2Sync = 18,
    NoiseLevel = 19,
    UnisonVoices = 20,
    UnisonDetune = 21,
    FilterEnvAmount = 22,
    FilterAttack = 23,
    FilterDecay = 24,
    FilterSustain = 25,
    FilterRelease = 26,
    GlideMs = 27,
    VelocitySensitivity = 28,
    PreHpCutoff = 29,
    PreHpRes = 30,
    PreDrive = 31,
    MixFeedback = 32,
    GlobalPitch = 33,
    FilterKeyTrack = 34,
    FilterDrive = 35,
    FilterShaper = 36,
    FilterFm = 37,
    FilterShaperMode = 38,
    SynthLegato = 39,
    SynthMono = 40,
};

enum class KickParam : uint16_t {
    Model = 0,
    Pitch = 1,
    Punch = 2,
    Decay = 3,
    Click = 4,
    Tone = 5,
    Velocity = 6,
};

enum class SnareParam : uint16_t {
    Model = 0,
    Body = 1,
    Ring = 2,
    Tune = 3,
    Snares = 4,
    Snap = 5,
    Decay = 6,
    Velocity = 7,
};

enum class ClapParam : uint16_t {
    Bursts = 0,
    Spread = 1,
    Tone = 2,
    Room = 3,
    Decay = 4,
    Velocity = 5,
};

enum class CymbalParam : uint16_t {
    Color = 0,
    Decay = 1,
    Width = 2,
    Velocity = 3,
};

enum class CrashParam : uint16_t {
    Color = 0,
    Spread = 1,
    Decay = 2,
    Velocity = 3,
};

enum class GateParam : uint16_t {
    InputGain = 0,
    Threshold = 1,
    Attack = 2,
    Release = 3,
    Hold = 4,
    Range = 5,
};

enum class CompressorParam : uint16_t {
    InputGain = 0,
    Threshold = 1,
    Ratio = 2,
    Attack = 3,
    Release = 4,
    Knee = 5,
    Makeup = 6,
};

enum class ExpanderParam : uint16_t {
    InputGain = 0,
    Threshold = 1,
    Ratio = 2,
    Attack = 3,
    Release = 4,
    Range = 5,
};

enum class LimiterParam : uint16_t {
    InputGain = 0,
    Ceiling = 1,
    Attack = 2,
    Release = 3,
    Drive = 4,
    Makeup = 5,
};

// -----------------------------------------------------------------------
// Audio-thread playback structs — zero strings, zero allocations.
// -----------------------------------------------------------------------

struct AutomationClipPlayback {
    uint16_t deviceIndex = 0;    // index into current track's device chain
    uint16_t localParamId = 0;   // device-local param (interpreted by kind)
    float clipStartBeat = 0.0f;
    float clipLengthBeats = 4.0f;
    int pointCount = 0;
    AutomationPointPlayback points[kMaxAutomationPlaybackPoints]{};
};

struct ModulationEdgePlayback {
    uint16_t deviceIndex = 0;    // index into current track's device chain
    uint16_t localParamId = 0;   // device-local param id
    uint16_t lfoId = 0;
    float amount = 0.0f;
};

// -----------------------------------------------------------------------
// Control-thread data (can use strings, vectors, etc.)
// -----------------------------------------------------------------------

struct ParamDescriptor {
    uint16_t localParamId;
    const char* stableName;       // for serialization
    const char* displayName;      // for UI
    float defaultValue;
    float minValue;
    float maxValue;
    bool automatable;
    bool modulatable;
};

struct AutomationPointState {
    double beat = 0.0;
    float value = 0.0f;
};

struct AutomationClipState {
    std::string id;
    /// Track the clip is rendered on in the arrangement view. The clip
    /// targets `deviceId`/`paramId` for audio routing, but is laid out
    /// on this track's lane. The two are independent.
    std::string homeTrackId;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    std::string deviceId;
    std::string paramId;
    std::vector<AutomationPointState> points;
};

} // namespace audioapp