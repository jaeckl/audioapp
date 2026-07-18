#pragma once

#include <algorithm>
#include <cmath>
#include <atomic>
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
#include <xmmintrin.h>
#endif
#include "audioapp/DeviceChain.hpp"
#include "audioapp/dsp/ProcessContext.hpp"

namespace audioapp {

inline bool isMeterSlotSubscribed(const ProcessContext& ctx, int8_t slot) noexcept {
    if (slot < 0 || slot >= ctx.maxDeviceMeters) {
        return false;
    }
    if (ctx.meterSlotSubscribed == nullptr) {
        return true;
    }
    return ctx.meterSlotSubscribed[slot];
}

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
                                 int maxMeters,
                                 const bool* meterSlotSubscribed = nullptr) noexcept {
    if (meters == nullptr || n.meterSlot < 0 || n.meterSlot >= maxMeters) {
        return;
    }
    if (meterSlotSubscribed != nullptr && !meterSlotSubscribed[n.meterSlot]) {
        return;
    }
    meters[n.meterSlot].gainReductionDb.store(runtime.gainReductionDb,
                                              std::memory_order_relaxed);
    meters[n.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
}

inline void multiplyScalarGain(float* buffer, int frames, float gain) noexcept {
    if (gain == 1.0f || frames <= 0) return;
    int frame = 0;
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
    const float32x4_t gains = vdupq_n_f32(gain);
    for (; frame + 4 <= frames; frame += 4)
        vst1q_f32(buffer + frame, vmulq_f32(vld1q_f32(buffer + frame), gains));
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
    const __m128 gains = _mm_set1_ps(gain);
    for (; frame + 4 <= frames; frame += 4)
        _mm_storeu_ps(buffer + frame, _mm_mul_ps(_mm_loadu_ps(buffer + frame), gains));
#endif
    for (; frame < frames; ++frame) buffer[frame] *= gain;
}

inline void applyStereoScalarGain(float* left, float* right, int frames, float gain) noexcept {
    multiplyScalarGain(left, frames, gain);
    multiplyScalarGain(right, frames, gain);
}

inline void multiplyPerFrameGain(float* buffer, int frames, const float* gain) noexcept {
    if (frames <= 0 || gain == nullptr) return;
    int frame = 0;
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
    for (; frame + 4 <= frames; frame += 4)
        vst1q_f32(buffer + frame,
                  vmulq_f32(vld1q_f32(buffer + frame), vld1q_f32(gain + frame)));
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
    for (; frame + 4 <= frames; frame += 4)
        _mm_storeu_ps(buffer + frame,
                      _mm_mul_ps(_mm_loadu_ps(buffer + frame),
                                 _mm_loadu_ps(gain + frame)));
#endif
    for (; frame < frames; ++frame) buffer[frame] *= gain[frame];
}

inline void mixDryWet(float* wet, const float* dry, int frames, float mix) noexcept {
    if (frames <= 0) return;
    if (mix == 1.0f) return;
    if (mix == 0.0f) {
        std::copy(dry, dry + frames, wet);
        return;
    }
    const float dryMix = 1.0f - mix;
    int frame = 0;
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
    const float32x4_t wetGains = vdupq_n_f32(mix);
    const float32x4_t dryGains = vdupq_n_f32(dryMix);
    for (; frame + 4 <= frames; frame += 4) {
        const auto mixed = vaddq_f32(vmulq_f32(vld1q_f32(wet + frame), wetGains),
                                     vmulq_f32(vld1q_f32(dry + frame), dryGains));
        vst1q_f32(wet + frame, mixed);
    }
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
    const __m128 wetGains = _mm_set1_ps(mix);
    const __m128 dryGains = _mm_set1_ps(dryMix);
    for (; frame + 4 <= frames; frame += 4) {
        const auto mixed = _mm_add_ps(_mm_mul_ps(_mm_loadu_ps(wet + frame), wetGains),
                                      _mm_mul_ps(_mm_loadu_ps(dry + frame), dryGains));
        _mm_storeu_ps(wet + frame, mixed);
    }
#endif
    for (; frame < frames; ++frame)
        wet[frame] = wet[frame] * mix + dry[frame] * dryMix;
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
