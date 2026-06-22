#pragma once

#include <cstring>

namespace audioapp {

struct AudioBlock {
    float* channelL = nullptr;
    float* channelR = nullptr;
    int numSamples = 0;

    AudioBlock() noexcept = default;

    AudioBlock(float* left, float* right, int frames) noexcept
        : channelL(left), channelR(right), numSamples(frames) {}

    void clear() noexcept {
        if (channelL) std::memset(channelL, 0, static_cast<size_t>(numSamples) * sizeof(float));
        if (channelR) std::memset(channelR, 0, static_cast<size_t>(numSamples) * sizeof(float));
    }

    void addFrom(const AudioBlock& src) noexcept {
        for (int i = 0; i < numSamples && i < src.numSamples; ++i) {
            channelL[i] += src.channelL[i];
            channelR[i] += src.channelR[i];
        }
    }

    void applyGain(float gain) noexcept {
        for (int i = 0; i < numSamples; ++i) {
            channelL[i] *= gain;
            channelR[i] *= gain;
        }
    }

    void applyPerFrameGain(const float* gain) noexcept {
        for (int i = 0; i < numSamples; ++i) {
            channelL[i] *= gain[i];
            channelR[i] *= gain[i];
        }
    }
};

} // namespace audioapp