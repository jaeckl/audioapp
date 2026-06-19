#pragma once

#include "audioapp/SamplerFilter.hpp"

#include <cstdint>

namespace audioapp {

static constexpr int kMetallicResonatorCount = 8;

struct MetallicResonatorState {
    float freq = 1000.0f;
    BiquadCoeffs coeffs{};
    BiquadState stateL{};
    BiquadState stateR{};
};

struct MetallicNoiseVoiceRuntime {
    uint8_t active = 0;
    int pitch = 42;
    float velocity = 100.0f;
    double elapsedSec = 0.0;
    uint32_t noiseStateL = 0xA341316Cu;
    uint32_t noiseStateR = 0xC8013EA4u;
    BiquadCoeffs driverLpCoeffs{};
    BiquadCoeffs driverHpCoeffs{};
    BiquadCoeffs bodyBpfCoeffs{};
    BiquadCoeffs midWashCoeffs{};
    BiquadState driverLpStateL{};
    BiquadState driverLpStateR{};
    BiquadState driverHpStateL{};
    BiquadState driverHpStateR{};
    BiquadState bodyBpfStateL{};
    BiquadState bodyBpfStateR{};
    BiquadState midWashStateL{};
    BiquadState midWashStateR{};
    MetallicResonatorState resonators[kMetallicResonatorCount]{};
    float resFreqRand[kMetallicResonatorCount]{};
    float cachedBrightNorm = -1.0f;
    float cachedSpreadNorm = -1.0f;
    float cachedSampleRate = 0.0f;
};

struct MetallicNoiseTimbre {
    // Core shape
    float decaySec = 0.4f;        // total decay time (0=short, 1=long mapped)
    float lpSweepStartHz = 14000.0f;
    float lpSweepEndHz = 800.0f;
    float lpSweepTau = 0.18f;     // how fast LP sweeps down (larger = slower)
    float hpShimmerHz = 6000.0f;
    float hpShimmerAmount = 0.15f;
    float bodyHz = 220.0f;
    float bodyQ = 3.5f;
    float bodyAmount = 0.22f;
    float midWashHz = 2600.0f;
    float midWashQ = 0.7f;
    float midWashAmount = 0.0f;
    // Resonator bank
    float resMinHz = 400.0f;
    float resMaxHz = 16000.0f;
    float resQ = 4.0f;
    float resMix = 0.55f;
    float resExciteRaw = 0.55f;   // raw-noise fraction into resonator bank
    float driverMix = 0.12f;      // direct LP noise in output (wash layer)
    float crashNoiseMix = 0.0f;   // extra broadband noise at attack (crash only)
    // Attack
    float thwackAmount = 0.30f;
    float thwackDecaySec = 0.004f;
    // Stereo
    float widthAmount = 0.35f;    // 0=mono, 1=max spread
    float widthDetuneCents = 8.0f; // detune between L/R resonators
};

void triggerMetallicNoiseVoice(MetallicNoiseVoiceRuntime& voice,
                               int pitch, float velocity) noexcept;

void updateResonatorBank(MetallicNoiseVoiceRuntime& voice,
                         const MetallicNoiseTimbre& timbre,
                         float brightNorm,
                         float spreadNorm,
                         float sampleRate) noexcept;

/// Generate stereo metallic noise output. Returns left sample, right via outR.
float metallicNoiseSampleL(MetallicNoiseVoiceRuntime& voice,
                           const MetallicNoiseTimbre& timbre,
                           double sampleRate,
                           float velocityGain,
                           float outputGain) noexcept;

float metallicNoiseSampleR(MetallicNoiseVoiceRuntime& voice,
                           const MetallicNoiseTimbre& timbre,
                           double sampleRate,
                           float velocityGain,
                           float outputGain) noexcept;

} // namespace audioapp