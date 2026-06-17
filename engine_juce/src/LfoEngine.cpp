#include "audioapp/ProjectJson.hpp"

#include <cmath>

namespace audioapp {

float lfoEvaluate(LfoWaveform waveform, float phase) noexcept {
    // phase is 0..1, wrap to [0, 1)
    phase = phase - std::floor(phase);
    switch (waveform) {
    case LfoWaveform::Sine:
        return std::sin(phase * 6.283185307f);
    case LfoWaveform::Tri:
        return 1.0f - 4.0f * std::abs(phase - 0.5f);
    case LfoWaveform::Saw:
        return 2.0f * phase - 1.0f;
    case LfoWaveform::Square:
        return phase < 0.5f ? 1.0f : -1.0f;
    case LfoWaveform::Ramp:
        return 1.0f - 2.0f * phase;
    }
    return 0.0f;
}

double lfoSyncBeats(int syncDivision) noexcept {
    switch (syncDivision) {
    case 0:  return 0.0;      // free (Hz mode)
    case 1:  return 1.0;      // 1/1
    case 2:  return 0.5;      // 1/2
    case 3:  return 0.25;     // 1/4
    case 4:  return 0.125;    // 1/8
    case 5:  return 0.0625;   // 1/16
    default: return 0.25;
    }
}

} // namespace audioapp