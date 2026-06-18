#include "audioapp/SamplerFilter.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

constexpr float kPi = 3.14159265358979323846f;

} // namespace

float normalizedCutoffToHz(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    const float minHz = 40.0f;
    const float maxHz = 16000.0f;
    return minHz * std::pow(maxHz / minHz, clamped);
}

float normalizedQToValue(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 0.5f + clamped * 7.5f;
}

void cookSamplerBiquad(BiquadCoeffs& coeffs,
                       int mode,
                       float sampleRate,
                       float cutoffHz,
                       float q) noexcept {
    if (sampleRate <= 0.0f) {
        coeffs = BiquadCoeffs{};
        return;
    }

    const float omega = 2.0f * kPi * std::clamp(cutoffHz, 20.0f, sampleRate * 0.45f) / sampleRate;
    const float sinOmega = std::sin(omega);
    const float cosOmega = std::cos(omega);
    const float alpha = sinOmega / (2.0f * std::max(q, 0.1f));

    float b0 = 0.0f;
    float b1 = 0.0f;
    float b2 = 0.0f;
    float a0 = 1.0f;
    float a1 = 0.0f;
    float a2 = 0.0f;

    switch (mode) {
    case 1: // HP
        b0 = (1.0f + cosOmega) * 0.5f;
        b1 = -(1.0f + cosOmega);
        b2 = (1.0f + cosOmega) * 0.5f;
        a0 = 1.0f + alpha;
        a1 = -2.0f * cosOmega;
        a2 = 1.0f - alpha;
        break;
    case 2: // BP
        b0 = alpha;
        b1 = 0.0f;
        b2 = -alpha;
        a0 = 1.0f + alpha;
        a1 = -2.0f * cosOmega;
        a2 = 1.0f - alpha;
        break;
    case 3: // notch
        b0 = 1.0f;
        b1 = -2.0f * cosOmega;
        b2 = 1.0f;
        a0 = 1.0f + alpha;
        a1 = -2.0f * cosOmega;
        a2 = 1.0f - alpha;
        break;
    case 0:
    default: // LP
        b0 = (1.0f - cosOmega) * 0.5f;
        b1 = 1.0f - cosOmega;
        b2 = (1.0f - cosOmega) * 0.5f;
        a0 = 1.0f + alpha;
        a1 = -2.0f * cosOmega;
        a2 = 1.0f - alpha;
        break;
    }

    coeffs.b0 = b0 / a0;
    coeffs.b1 = b1 / a0;
    coeffs.b2 = b2 / a0;
    coeffs.a1 = a1 / a0;
    coeffs.a2 = a2 / a0;
}

float processBiquadSample(float input,
                          const BiquadCoeffs& coeffs,
                          BiquadState& state) noexcept {
    const float output =
        coeffs.b0 * input + state.z1;
    state.z1 = coeffs.b1 * input - coeffs.a1 * output + state.z2;
    state.z2 = coeffs.b2 * input - coeffs.a2 * output;
    return output;
}

int combDelaySamples(float sampleRate, float cutoffHz) noexcept {
    if (sampleRate <= 0.0f || cutoffHz <= 0.0f) {
        return 2;
    }
    const int delay =
        static_cast<int>(std::lround(sampleRate / std::clamp(cutoffHz, 40.0f, 8000.0f)));
    return std::clamp(delay, 2, kCombMaxDelay - 1);
}

float processCombSample(float input,
                        CombFilterState& state,
                        int delaySamples,
                        float feedback) noexcept {
    const int clampedDelay = std::clamp(delaySamples, 2, kCombMaxDelay - 1);
    const int readIndex =
        (state.writeIndex - clampedDelay + kCombMaxDelay) % kCombMaxDelay;
    const float delayed = state.buffer[readIndex];
    const float clampedFeedback = std::clamp(feedback, 0.0f, 0.98f);
    const float output = input + clampedFeedback * delayed;
    state.buffer[state.writeIndex] = output;
    state.writeIndex = (state.writeIndex + 1) % kCombMaxDelay;
    return output;
}

} // namespace audioapp
