#pragma once

namespace audioapp {

/// Simple test oscillator for Milestone 01 (offline render tests first).
class TestOscillator {
public:
    void setFrequency(float hz) noexcept { frequencyHz_ = hz; }
    void setEnabled(bool enabled) noexcept { enabled_ = enabled; }

    void processBlock(float* samples, int numSamples, double sampleRate) noexcept;

private:
    float frequencyHz_ = 440.0f;
    float phase_ = 0.0f;
    bool enabled_ = false;
};

} // namespace audioapp
