#include "audioapp/TestOscillator.hpp"

#include <cmath>

namespace audioapp {

void TestOscillator::processBlock(float* samples, int numSamples, double sampleRate) noexcept {
    if (!enabled_ || sampleRate <= 0.0) {
        for (int i = 0; i < numSamples; ++i) {
            samples[i] = 0.0f;
        }
        return;
    }

    const float phaseIncrement = static_cast<float>(2.0 * 3.14159265358979323846 * frequencyHz_ / sampleRate);

    for (int i = 0; i < numSamples; ++i) {
        samples[i] = 0.2f * std::sin(phase_);
        phase_ += phaseIncrement;
        if (phase_ > 6.283185307179586f) {
            phase_ -= 6.283185307179586f;
        }
    }
}

} // namespace audioapp
