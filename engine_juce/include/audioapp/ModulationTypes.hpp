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

/// Modulator types.
enum class ModulatorType : int {
    Lfo = 0,
    Envelope = 1,  // unified envelope replaces old Adsr=1, Adr=2
    RandomGenerator = 2,
};

/// Curve shapes for the unified envelope modulator.
enum class EnvelopeCurve : int {
    Adsr = 0,
    Asr = 1,
    Adr = 2,
    Ahdsr = 3,
};

/// 0=free (Hz / per-note clock), 1=sync to project phase, 2=retrigger on note.
enum class ModulatorRetrigger : int {
    Free = 0,
    Sync = 1,
    OnNote = 2,
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