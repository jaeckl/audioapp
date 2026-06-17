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
};

/// mode: 0 LP, 1 HP, 2 BP, 3 notch
void cookSamplerBiquad(BiquadCoeffs& coeffs,
                       int mode,
                       float sampleRate,
                       float cutoffHz,
                       float q) noexcept;

float processBiquadSample(float input,
                          const BiquadCoeffs& coeffs,
                          BiquadState& state) noexcept;

float normalizedCutoffToHz(float normalized) noexcept;

float normalizedQToValue(float normalized) noexcept;

} // namespace audioapp
