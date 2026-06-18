#pragma once

#include "audioapp/SamplerFilter.hpp"

#include <cstdint>

namespace audioapp {

static constexpr int kMetallicNoiseBandCount = 4;

struct MetallicNoiseVoiceRuntime {
    uint8_t active = 0;
    int pitch = 42;
    float velocity = 100.0f;
    double elapsedSec = 0.0;
    float noiseSeed = 0.321f;
    BiquadCoeffs hpCoeffs{};
    BiquadCoeffs bandCoeffs[kMetallicNoiseBandCount]{};
    BiquadState hpState{};
    BiquadState bandStates[kMetallicNoiseBandCount]{};
};

struct MetallicNoiseTimbre {
    float metalNorm = 0.55f;
    float brightNorm = 0.60f;
    float decayNorm = 0.50f;
    float chokeNorm = 0.0f;
    float minDecaySec = 0.08f;
    float maxDecaySec = 0.45f;
    float hpStartHz = 6000.0f;
    float hpEndHz = 1200.0f;
    float sweepTauSec = 0.035f;
    float attackTauSec = 0.0012f;
    float bandQ = 1.8f;
    float washGain = 0.85f;
    float attackGain = 0.55f;
};

void triggerMetallicNoiseVoice(MetallicNoiseVoiceRuntime& voice, int pitch, float velocity) noexcept;

void updateMetallicNoiseBandFilters(MetallicNoiseVoiceRuntime& voice,
                                    float hpHz,
                                    float metalNorm,
                                    float sampleRate) noexcept;

float metallicNoiseSample(MetallicNoiseVoiceRuntime& voice,
                          const MetallicNoiseTimbre& timbre,
                          double sampleRate,
                          float velocityGain,
                          float outputGain) noexcept;

} // namespace audioapp
