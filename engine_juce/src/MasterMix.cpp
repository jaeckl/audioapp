#include "audioapp/MasterMix.hpp"

#include <cmath>

namespace audioapp {

namespace {
constexpr float kPi = 3.14159265358979323846f;
constexpr float kTwoPi = kPi * 2.0f;
} // namespace

void addSineBlock(float* inOut,
                  int numSamples,
                  double sampleRate,
                  float frequencyHz,
                  float& phase,
                  float gain) noexcept {
    if (inOut == nullptr || numSamples <= 0 || sampleRate <= 0.0 || frequencyHz <= 0.0f || gain <= 0.0f) {
        return;
    }

    const float phaseIncrement =
        static_cast<float>(2.0 * 3.14159265358979323846 * frequencyHz / sampleRate);

    for (int i = 0; i < numSamples; ++i) {
        inOut[i] += gain * std::sin(phase);
        phase += phaseIncrement;
        if (phase >= kTwoPi) {
            phase -= kTwoPi;
        }
    }
}

} // namespace audioapp
