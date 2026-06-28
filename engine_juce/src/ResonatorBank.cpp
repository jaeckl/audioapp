#include "audioapp/ResonatorBank.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {
namespace {

constexpr float kPi = 3.14159265358979323846f;

float clampFinite(float value, float low, float high, float fallback) noexcept {
    return std::isfinite(value) ? std::clamp(value, low, high) : fallback;
}

ResonatorBandCoefficients makeCoefficients(int band,
                                           double sampleRate,
                                           const ResonatorBankParams& params) noexcept {
    const float root = clampFinite(params.rootHz, 32.7032f, 2093.005f, 130.8128f);
    const float spread = clampFinite(params.spread, 0.5f, 1.5f, 1.0f);
    const float baseDecay = clampFinite(params.decaySeconds, 0.08f, 12.0f, 1.25f);
    const float damping = clampFinite(params.damping, 0.0f, 1.0f, 0.35f);
    const float color = clampFinite(params.colorDbPerOctave, -12.0f, 12.0f, 0.0f);
    const float width = clampFinite(params.width, 0.0f, 2.0f, 1.0f);

    const float ratio = std::pow(static_cast<float>(band + 1), spread);
    const float maxFrequency = static_cast<float>(sampleRate * 0.45);
    const float rawFrequency = root * ratio;
    const float frequency = std::clamp(rawFrequency, 20.0f, maxFrequency);
    const float octave = std::log2(std::max(ratio, 1.0f));
    const float bandDecay = std::max(0.03f, baseDecay * std::exp(-2.4f * damping * octave));
    const float radius = std::clamp(
        std::pow(10.0f, -3.0f / (bandDecay * static_cast<float>(sampleRate))),
        0.0f,
        0.999995f);
    const float omega = 2.0f * kPi * frequency / static_cast<float>(sampleRate);

    const float modalGain = rawFrequency <= maxFrequency
        ? std::pow(10.0f, color * octave / 20.0f)
        : 0.0f;
    constexpr float kPositions[kResonatorBandCount] = {-1.0f, 1.0f, -0.6f, 0.6f, -0.25f, 0.25f};
    const float pan = std::clamp(kPositions[band] * width, -1.0f, 1.0f);
    const float angle = (pan + 1.0f) * kPi * 0.25f;

    ResonatorBandCoefficients result;
    // Energy-normalized excitation keeps long-decay modes audible. Using
    // (1 - radius) gives unity response to a sustained sine, but makes a
    // drum-like impulse nearly silent once T60 exceeds a few hundred ms.
    result.b = std::sqrt(std::max(0.0f, 1.0f - radius * radius));
    result.a1 = 2.0f * radius * std::cos(omega);
    result.a2 = -(radius * radius);
    result.gainL = modalGain * std::cos(angle);
    result.gainR = modalGain * std::sin(angle);
    return result;
}

float processMode(float input,
                  const ResonatorBandCoefficients& coefficients,
                  ResonatorBandState& state) noexcept {
    float output = coefficients.b * (input - state.x2) +
                   coefficients.a1 * state.y1 + coefficients.a2 * state.y2;
    if (!std::isfinite(output) || std::abs(output) > 32.0f) {
        output = 0.0f;
        state = {};
    }
    state.x2 = input;
    state.y2 = state.y1;
    state.y1 = std::abs(output) < 1.0e-20f ? 0.0f : output;
    return output;
}

} // namespace

void processResonatorBankStereoBlock(float* left,
                                     float* right,
                                     int numFrames,
                                     double sampleRate,
                                     const ResonatorBankParams& params,
                                     ResonatorBankRuntime& runtime) noexcept {
    if (left == nullptr || right == nullptr || numFrames <= 0 || sampleRate < 8000.0) return;

    ResonatorBandCoefficients targets[kResonatorBandCount];
    for (int band = 0; band < kResonatorBandCount; ++band) {
        targets[band] = makeCoefficients(band, sampleRate, params);
    }
    float modalGainSum = 0.0f;
    for (const auto& target : targets) {
        modalGainSum += std::hypot(target.gainL, target.gainR);
    }
    if (modalGainSum > 0.0f) {
        const float gainScale = 1.0f / modalGainSum;
        for (auto& target : targets) {
            target.gainL *= gainScale;
            target.gainR *= gainScale;
        }
    }

    const float targetMix = clampFinite(params.mix, 0.0f, 1.0f, 0.5f);
    if (!runtime.initialized || runtime.sampleRate != sampleRate) {
        if (runtime.sampleRate != 0.0 && runtime.sampleRate != sampleRate) {
            for (auto& bandStates : runtime.states) {
                for (auto& state : bandStates) state = {};
            }
        }
        for (int band = 0; band < kResonatorBandCount; ++band) runtime.coefficients[band] = targets[band];
        runtime.smoothedMix = targetMix;
        runtime.sampleRate = sampleRate;
        runtime.initialized = true;
    }

    const float invFrames = 1.0f / static_cast<float>(numFrames);
    for (int frame = 0; frame < numFrames; ++frame) {
        const float dryL = std::isfinite(left[frame]) ? left[frame] : 0.0f;
        const float dryR = std::isfinite(right[frame]) ? right[frame] : 0.0f;
        float wetL = 0.0f;
        float wetR = 0.0f;

        for (int band = 0; band < kResonatorBandCount; ++band) {
            auto& current = runtime.coefficients[band];
            const auto& target = targets[band];
            current.b += (target.b - current.b) * invFrames;
            current.a1 += (target.a1 - current.a1) * invFrames;
            current.a2 += (target.a2 - current.a2) * invFrames;
            current.gainL += (target.gainL - current.gainL) * invFrames;
            current.gainR += (target.gainR - current.gainR) * invFrames;

            wetL += processMode(dryL, current, runtime.states[band][0]) * current.gainL;
            wetR += processMode(dryR, current, runtime.states[band][1]) * current.gainR;
        }

        runtime.smoothedMix += (targetMix - runtime.smoothedMix) * invFrames;
        const float mix = std::clamp(runtime.smoothedMix, 0.0f, 1.0f);
        const float dryGain = std::cos(mix * kPi * 0.5f);
        const float wetGain = std::sin(mix * kPi * 0.5f);
        left[frame] = std::clamp(dryL * dryGain + wetL * wetGain, -8.0f, 8.0f);
        right[frame] = std::clamp(dryR * dryGain + wetR * wetGain, -8.0f, 8.0f);
    }
}

} // namespace audioapp
