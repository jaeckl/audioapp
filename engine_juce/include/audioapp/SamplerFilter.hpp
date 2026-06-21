#pragma once

namespace audioapp {

struct BiquadCoeffs {
    float b0 = 1.0f;
    float b1 = 0.0f;
    float b2 = 0.0f;
    float a1 = 0.0f;
    float a2 = 0.0f;
};

struct BiquadState {
    float z1 = 0.0f;
    float z2 = 0.0f;
    float lastCutoffHz = -1.0f;
};

static constexpr int kCombMaxDelay = 1024;

struct CombFilterState {
    float buffer[kCombMaxDelay]{};
    int writeIndex = 0;
};

/// mode: 0 LP, 1 HP, 2 BP, 3 notch, 4 comb
void cookSamplerBiquad(BiquadCoeffs& coeffs,
                       int mode,
                       float sampleRate,
                       float cutoffHz,
                       float q) noexcept;

float processBiquadSample(float input,
                          const BiquadCoeffs& coeffs,
                          BiquadState& state) noexcept;

int combDelaySamples(float sampleRate, float cutoffHz) noexcept;

float processCombSample(float input,
                        CombFilterState& state,
                        int delaySamples,
                        float feedback) noexcept;

float normalizedCutoffToHz(float normalized) noexcept;

float normalizedQToValue(float normalized) noexcept;

} // namespace audioapp
