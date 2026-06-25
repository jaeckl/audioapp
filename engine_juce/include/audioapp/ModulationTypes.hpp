#pragma once

#include <algorithm>
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
    Sequencer = 3,
    Curve = 4,
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
/// Pure discrete waveform with no morphing.
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

/// Evaluate a single waveform shape by index (0–4: Sine, Tri, Saw, Square, Ramp).
inline float lfoEvaluateIndex(int idx, float phase) noexcept {
    return lfoEvaluate(static_cast<LfoWaveform>(idx), phase);
}

/// Apply phase skew via spread [0, 1]. 0.5 = symmetric (no change).
inline float lfoApplySpread(float phase, float spread) noexcept {
    phase = phase - std::floor(phase);
    const float s = std::clamp(spread, 0.0f, 1.0f);
    if (std::abs(s - 0.5f) <= 0.001f) return phase;
    if (s < 0.5f) {
        // Compress rise, expand fall
        const float split = s * 2.0f; // [0, 1)
        if (phase < split) {
            return phase / split * 0.5f;
        } else {
            return 0.5f + (phase - split) / (1.0f - split) * 0.5f;
        }
    } else {
        // Expand rise, compress fall
        const float split = s * 2.0f - 1.0f; // [0, 1)
        if (phase < 0.5f) {
            return phase / 0.5f * split;
        } else {
            return split + (phase - 0.5f) / 0.5f * (1.0f - split);
        }
    }
}

/// Evaluate LFO waveform with continuous morph [0,1] and phase spread [0,1].
/// morph: 0=sine, 0.25=tri, 0.5=saw, 0.75=square, 1.0=ramp (linear blend between).
/// spread: 0.5=symmetric, <0.5 skew left, >0.5 skew right.
inline float lfoEvaluateMorph(float morph, float spread, float phase) noexcept {
    phase = lfoApplySpread(phase, spread);
    const float m = std::clamp(morph, 0.0f, 1.0f);
    // Map [0,1] to segment index [0,3] for blending between 5 waveforms
    const float seg = m * 4.0f;
    const int idx = static_cast<int>(seg);
    const float frac = seg - static_cast<float>(idx);
    if (idx >= 4) return lfoEvaluateIndex(4, phase);
    const float a = lfoEvaluateIndex(idx, phase);
    const float b = lfoEvaluateIndex(idx + 1, phase);
    return a + (b - a) * frac;
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