#pragma once

#include <cmath>
#include <string>

namespace audioapp {

/// LFO waveform types.
enum class LfoWaveform : int {
    Sine = 0,
    Tri,
    Saw,
    Square,
    Ramp,
};

enum class ModulatorType : int {
    Lfo = 0,
    Adsr = 1,
    Adr = 2,
};

/// 0=free (Hz / per-note clock), 1=sync to project phase, 2=retrigger on note.
enum class ModulatorRetrigger : int {
    Free = 0,
    Sync = 1,
    OnNote = 2,
};

/// Persistent modulator state (control thread). Serialized as project "lfos".
struct LfoState {
    int id = 0;
    int modulatorType = 0;
    int retrigger = 0;
    int waveform = 0;
    float rate = 1.0f;
    int syncDivision = 0;
    float phase = 0.0f;
    int polarity = 0;
    float attack = 0.1f;
    float decay = 0.25f;
    float sustain = 0.7f;
    float release = 0.35f;
};

struct ModulationEdge {
    int lfoId = 0;
    std::string deviceId;
    std::string paramId;
    float amount = 0.0f;
};

/// Evaluate an LFO waveform at a given wrapped phase [0, 1).
inline float lfoEvaluate(LfoWaveform waveform, float phase) noexcept {
    phase = phase - std::floor(phase);
    switch (waveform) {
    case LfoWaveform::Sine:   return std::sin(phase * 6.283185307f);
    case LfoWaveform::Tri:    return 1.0f - 4.0f * std::abs(phase - 0.5f);
    case LfoWaveform::Saw:    return 2.0f * phase - 1.0f;
    case LfoWaveform::Square: return phase < 0.5f ? 1.0f : -1.0f;
    case LfoWaveform::Ramp:   return 1.0f - 2.0f * phase;
    }
    return 0.0f;
}

/// Map sync division index to beat multiplier.
inline double lfoSyncBeats(int syncDivision) noexcept {
    switch (syncDivision) {
    case 0:  return 0.0;
    case 1:  return 1.0;
    case 2:  return 0.5;
    case 3:  return 0.25;
    case 4:  return 0.125;
    case 5:  return 0.0625;
    default: return 0.25;
    }
}

} // namespace audioapp