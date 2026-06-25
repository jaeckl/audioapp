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
    FilterDecay = 13,
    Octave = 14,
    SubOctave = 15,
};

enum class PhaseModSynthParam : uint16_t {
    // Operator 1
    Op1Level = 0,
    Op1Fine = 1,
    Op1Attack = 2,
    Op1Decay = 3,
    Op1Sustain = 4,
    Op1Release = 5,
    // Operator 2
    Op2Level = 6,
    Op2Fine = 7,
    Op2Attack = 8,
    Op2Decay = 9,
    Op2Sustain = 10,
    Op2Release = 11,
    // Operator 3
    Op3Level = 12,
    Op3Fine = 13,
    Op3Attack = 14,
    Op3Decay = 15,
    Op3Sustain = 16,
    Op3Release = 17,
    // Operator 4
    Op4Level = 18,
    Op4Fine = 19,
    Op4Attack = 20,
    Op4Decay = 21,
    Op4Sustain = 22,
    Op4Release = 23,
    // Filter
    FilterCutoff = 24,
    FilterQ = 25,
    FilterEnvAmount = 26,
    FilterMode = 27,
    FilterAttack = 28,
    FilterDecay = 29,
    FilterSustain = 30,
    FilterRelease = 31,
    FilterKeyTrack = 32,
    // Amp
    AmpAttack = 33,
    AmpDecay = 34,
    AmpSustain = 35,
    AmpRelease = 36,
    // Global
    Feedback = 37,
    MasterVol = 38,
    LfoRate = 39,
    LfoAmount = 40,
    VibratoDepth = 41,
    VibratoRate = 42,
};

// ─── Frequency FX suite (added for Filter / 4-Band EQ / Ring Mod) ────────────
//
// These per-kind enums are used purely for the audio-thread dispatch in
// `applyModulation(...)` — they share the same uint16_t slot space as the
// other device kinds via the `ParamKind` tag above, so the audio thread can
// route by kind without colliding.

enum class FilterParam : uint16_t {
    Cutoff     = 0,
    Resonance  = 1,
    Mode       = 2,
};

enum class FourBandEqParam : uint16_t {
    // Band 1 (Low Shelf)
    Band1Freq  = 0,
    Band1Gain  = 1,
    Band1Q     = 2,
    // Band 2 (Low Mid)
    Band2Freq  = 3,
    Band2Gain  = 4,
    Band2Q     = 5,
    // Band 3 (High Mid)
    Band3Freq  = 6,
    Band3Gain  = 7,
    Band3Q     = 8,
    // Band 4 (High Shelf)
    Band4Freq  = 9,
    Band4Gain  = 10,
    Band4Q     = 11,
};

enum class FrequencyShifterParam : uint16_t {
    Shift = 0,
};

// -----------------------------------------------------------------------
// ParamKind — distinguishes which per-device enum a `localParamId` refers
// to. Without this tag, multiple device kinds (CommonParam, SubtractiveParam,
// SamplerParam, …) all encode their first parameter as raw value 0, and the
// runtime's `if (pid == CommonParam::Gain) skip` check accidentally skips
// every device's "first param" (filterCutoff, attack, etc.) on the audio
// thread. The fix is to pack `(ParamKind, perKindId)` into the uint16_t so
// the runtime can disambiguate.
//
// Encoding:  bits 11..15 = kind tag (5 bits, 0..31)
//            bits  0..10 = per-kind enum value (11 bits, 0..2047)
// -----------------------------------------------------------------------

enum class ParamKind : uint16_t {
    Common           = 0,
    Oscillator       = 1,
    Sampler          = 2,
    SubtractiveSynth = 3,
    KickGenerator    = 4,
    SnareGenerator   = 5,
    ClapGenerator    = 6,
    CymbalGenerator  = 7,
    CrashGenerator   = 8,
    Gate             = 9,
    Compressor       = 10,
    Expander         = 11,
    Limiter          = 12,
    TrackGain        = 13,
    BassSynth        = 14,
    PhaseModSynth    = 15,
    Filter           = 16,
    FourBandEq       = 17,
    FrequencyShifter = 18,
};

constexpr uint16_t kParamKindShift      = 11;
constexpr uint16_t kParamKindMask       = 0xF800;
constexpr uint16_t kParamIdMask         = 0x07FF;

constexpr uint16_t packParamId(ParamKind kind, uint16_t perKindId) noexcept {
    return static_cast<uint16_t>((static_cast<uint16_t>(kind) << kParamKindShift) |
                                 (perKindId & kParamIdMask));
}

constexpr ParamKind unpackParamKind(uint16_t localParamId) noexcept {
    return static_cast<ParamKind>((localParamId & kParamKindMask) >> kParamKindShift);
}

constexpr uint16_t unpackParamId(uint16_t localParamId) noexcept {
    return static_cast<uint16_t>(localParamId & kParamIdMask);
}

// Encoded CommonParam values used in the runtime skip checks
// (e.g. "is this automation targeting the track gain?").
// Common kind has tag 0, so the encoded value equals the raw enum value.
constexpr uint16_t kEncodedCommonGain = 0;  // packParamId(ParamKind::Common, 0)
constexpr uint16_t kEncodedCommonPan  = 1;  // packParamId(ParamKind::Common, 1)

// -----------------------------------------------------------------------
// Audio-thread playback structs — zero strings, zero allocations.
// -----------------------------------------------------------------------

struct AutomationClipPlayback {
    uint16_t deviceIndex = 0;    // index into current track's device chain
    // Encoded (ParamKind, perKindId) — see packParamId. The kind tag is
    // required so that the audio thread can dispatch to the correct
    // per-kind enum without colliding with other kinds that reuse value 0.
    uint16_t localParamId = 0;
    float clipStartBeat = 0.0f;
    float clipLengthBeats = 4.0f;
    int pointCount = 0;
    AutomationPointPlayback points[kMaxAutomationPlaybackPoints]{};
};

struct ModulationEdgePlayback {
    uint16_t deviceIndex = 0;    // index into current track's device chain
    // Encoded (ParamKind, perKindId) — see packParamId.
    uint16_t localParamId = 0;
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