#pragma once

#include <algorithm>
#include <cmath>
#include <atomic>
#include "audioapp/DeviceChain.hpp"

namespace audioapp {

inline float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept {
    float peak = 0.0f;
    for (int i = 0; i < frameCount; ++i) {
        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
    }
    return peak;
}

inline void publishDynamicsMeters(const DeviceNodePlayback& n,
                                 const DynamicsRuntime& runtime,
                                 float inputPeak,
                                 DeviceMeterAtomic* meters,
                                 int maxMeters) noexcept {
    if (meters == nullptr || n.meterSlot < 0 || n.meterSlot >= maxMeters) {
        return;
    }
    meters[n.meterSlot].gainReductionDb.store(runtime.gainReductionDb,
                                              std::memory_order_relaxed);
    meters[n.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
}

inline void applyStereoScalarGain(float* left, float* right, int frames, float gain) noexcept {
    for (int f = 0; f < frames; ++f) {
        left[f] *= gain;
        right[f] *= gain;
    }
}

inline void multiplyPerFrameGain(float* buffer, int frames, const float* gain) noexcept {
    for (int f = 0; f < frames; ++f) {
        buffer[f] *= gain[f];
    }
}

inline void mixStereoPerFramePan(float* trackLeftL, float* trackRightL,
                                 const float* mono, int frames,
                                 const float* perFramePan) noexcept {
    for (int f = 0; f < frames; ++f) {
        const float angle = std::clamp(perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
        trackLeftL[f] += mono[f] * std::cos(angle);
        trackRightL[f] += mono[f] * std::sin(angle);
    }
}

} // namespace audioapp
