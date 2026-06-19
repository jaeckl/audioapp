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

/// ParamId replaces string paramId on the audio thread — enum dispatch (zero string ops).
enum class ParamId : uint16_t {
    Unknown = 0,
    // Universal
    Gain,
    Pan,
    // Oscillator
    Frequency,
    // Sampler & Subtractive shared
    FilterCutoff, FilterQ,
    Attack, Decay, Sustain, Release,
    RootPitch, RootFineTune,
    FilterEnvAmount, FilterAttack, FilterDecay, FilterSustain, FilterRelease,
    // SubtractiveSynth only
    Osc1Shape, Osc2Shape,
    Osc1Octave, Osc1Semi, Osc1Detune,
    Osc2Octave, Osc2Semi, Osc2Detune,
    OscMix, Osc1Sync, Osc2Sync, NoiseLevel, OscMixMode,
    UnisonVoices, UnisonDetune,
    GlideMs, VelocitySensitivity,
    PreHpCutoff, PreHpRes, PreDrive,
    MixFeedback, GlobalPitch,
    FilterKeyTrack, FilterDrive, FilterShaper, FilterFm, FilterShaperMode,
    SynthLegato, SynthMono,
    FilterMode,
    // Kick
    KickModel, KickPitch, KickPunch, KickDecay, KickClick, KickTone, KickVelocity,
    // Snare
    SnareModel, SnareBody, SnareRing, SnareTune, SnareSnares, SnareSnap, SnareDecay, SnareVelocity,
    // Clap
    ClapBursts, ClapSpread, ClapTone, ClapRoom, ClapDecay, ClapVelocity,
    // Cymbal
    CymbalColor, CymbalDecay, CymbalWidth, CymbalVelocity,
    // Crash
    CrashColor, CrashSpread, CrashDecay, CrashVelocity,
    // Dynamics common
    InputGain, Threshold, Ratio, CompKnee, CompMakeup,
    GateHold, GateRange,
    LimitCeiling, LimitDrive,
};

/// Resolve a string paramId to a ParamId (control thread, O(n) string scan).
ParamId paramIdFromString(const char* name) noexcept;
/// Reverse: ParamId to short string (for serialization).
const char* paramIdToString(ParamId id) noexcept;

struct AutomationClipPlayback {
    char deviceId[48]{};
    ParamId paramId = ParamId::Unknown;
    float clipStartBeat = 0.0f;
    float clipLengthBeats = 4.0f;
    int pointCount = 0;
    AutomationPointPlayback points[kMaxAutomationPlaybackPoints]{};
};

struct AutomationPointState {
    double beat = 0.0;
    float value = 0.0f;
};

struct AutomationClipState {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    std::string deviceId;
    std::string paramId;
    std::vector<AutomationPointState> points;
};

} // namespace audioapp