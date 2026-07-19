#include "audioapp/GranularGrainSimd.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define AUDIOAPP_GRANULAR_GRAIN_SIMD 1
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
#include <xmmintrin.h>
#define AUDIOAPP_GRANULAR_GRAIN_SIMD 1
#endif

namespace audioapp {
namespace {

constexpr float kPi = 3.14159265358979323846f;

#if AUDIOAPP_GRANULAR_GRAIN_SIMD

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
using SimdVec = float32x4_t;
static SimdVec simdSet1(float v) noexcept { return vdupq_n_f32(v); }
static SimdVec simdLoad(const float* p) noexcept { return vld1q_f32(p); }
static void simdStore(float* p, SimdVec v) noexcept { vst1q_f32(p, v); }
static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return vaddq_f32(a, b); }
static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return vsubq_f32(a, b); }
static SimdVec simdMul(SimdVec a, SimdVec b) noexcept { return vmulq_f32(a, b); }
static float horizontalSum(SimdVec v) noexcept {
    const float32x2_t low = vget_low_f32(v);
    const float32x2_t high = vget_high_f32(v);
    const float32x2_t sum2 = vadd_f32(low, high);
    return vget_lane_f32(vpadd_f32(sum2, sum2), 0);
}
#else
using SimdVec = __m128;
static SimdVec simdSet1(float v) noexcept { return _mm_set1_ps(v); }
static SimdVec simdLoad(const float* p) noexcept { return _mm_loadu_ps(p); }
static void simdStore(float* p, SimdVec v) noexcept { _mm_storeu_ps(p, v); }
static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return _mm_add_ps(a, b); }
static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return _mm_sub_ps(a, b); }
static SimdVec simdMul(SimdVec a, SimdVec b) noexcept { return _mm_mul_ps(a, b); }
static float horizontalSum(SimdVec v) noexcept {
    alignas(16) float lanes[4];
    _mm_storeu_ps(lanes, v);
    return lanes[0] + lanes[1] + lanes[2] + lanes[3];
}
#endif

static void hannWindows(const float* phases, float* windows, int count) noexcept {
    for (int i = 0; i < count; ++i) {
        windows[i] = 0.5f - 0.5f * std::cos(phases[i] * 2.0f * kPi);
    }
}

static void gatherLerp(const float* pcm, int frameCount, const float* positions,
                       float* samples, int count) noexcept {
    const int last = std::max(0, frameCount - 2);
    for (int i = 0; i < count; ++i) {
        const float pos = positions[i];
        const int index = std::min(static_cast<int>(pos), last);
        const float fraction = pos - static_cast<float>(index);
        samples[i] = pcm[index] * (1.0f - fraction) + pcm[index + 1] * fraction;
    }
}

#endif // AUDIOAPP_GRANULAR_GRAIN_SIMD

} // namespace

bool renderGranularGrainBankSimd(const float* pcm,
                                 int frameCount,
                                 const float* phases,
                                 const float* positions,
                                 const float* pans,
                                 int grainCount,
                                 float amp,
                                 float& leftOut,
                                 float& rightOut,
                                 bool stereoSpread) noexcept {
#if !AUDIOAPP_GRANULAR_GRAIN_SIMD
    (void)pcm;
    (void)frameCount;
    (void)phases;
    (void)positions;
    (void)pans;
    (void)grainCount;
    (void)amp;
    (void)leftOut;
    (void)rightOut;
    (void)stereoSpread;
    return false;
#else
    if (pcm == nullptr || phases == nullptr || positions == nullptr ||
        frameCount < 2 || grainCount <= 0 || grainCount > kGranularMaxGrains) {
        return false;
    }

    float left = 0.0f;
    float right = 0.0f;
    int g = 0;
    for (; g + 4 <= grainCount; g += 4) {
        alignas(16) float windows[4];
        alignas(16) float samples[4];
        hannWindows(phases + g, windows, 4);
        gatherLerp(pcm, frameCount, positions + g, samples, 4);

        SimdVec values = simdMul(simdMul(simdLoad(samples), simdLoad(windows)), simdSet1(amp));
        if (!stereoSpread || pans == nullptr) {
            left += horizontalSum(values);
            continue;
        }

        alignas(16) float valueLanes[4];
        simdStore(valueLanes, values);
        for (int i = 0; i < 4; ++i) {
            const float pan = std::clamp(pans[g + i], 0.0f, 1.0f);
            left += valueLanes[i] * std::sqrt(1.0f - pan);
            right += valueLanes[i] * std::sqrt(pan);
        }
    }

    for (; g < grainCount; ++g) {
        const float window = 0.5f - 0.5f * std::cos(phases[g] * 2.0f * kPi);
        const int last = frameCount - 2;
        const int index = std::min(static_cast<int>(positions[g]), last);
        const float fraction = positions[g] - static_cast<float>(index);
        const float sample = pcm[index] * (1.0f - fraction) + pcm[index + 1] * fraction;
        const float value = sample * window * amp;
        if (!stereoSpread || pans == nullptr) {
            left += value;
        } else {
            const float pan = std::clamp(pans[g], 0.0f, 1.0f);
            left += value * std::sqrt(1.0f - pan);
            right += value * std::sqrt(pan);
        }
    }

    leftOut = left;
    rightOut = stereoSpread ? right : left;
    return true;
#endif
}

} // namespace audioapp
