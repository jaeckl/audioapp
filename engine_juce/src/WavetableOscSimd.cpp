#include "audioapp/WavetableOscSimd.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define AUDIOAPP_WAVETABLE_OSC_SIMD 1
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
#include <xmmintrin.h>
#define AUDIOAPP_WAVETABLE_OSC_SIMD 1
#endif

namespace audioapp {
namespace {

#if AUDIOAPP_WAVETABLE_OSC_SIMD

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

static void wrapPhases01(float* phases, int count) noexcept {
    for (int i = 0; i < count; ++i) {
        float p = phases[i];
        if (p >= 1.0f || p < 0.0f) {
            p -= std::floor(p);
        }
        phases[i] = p;
    }
}

static float gatherLerpLane(const float* table,
                            int frameA,
                            int frameB,
                            int frameLength,
                            float phase,
                            float frameFrac) noexcept {
    float p = phase;
    if (p >= 1.0f || p < 0.0f) {
        p -= std::floor(p);
    }
    const float pos = p * static_cast<float>(frameLength);
    const int idx = static_cast<int>(pos) % frameLength;
    const int idxNext = (idx + 1) % frameLength;
    const float t = pos - std::floor(pos);

    const float sA = table[frameA * frameLength + idx];
    const float sA1 = table[frameA * frameLength + idxNext];
    const float sB = table[frameB * frameLength + idx];
    const float sB1 = table[frameB * frameLength + idxNext];
    const float a = sA + t * (sA1 - sA);
    const float b = sB + t * (sB1 - sB);
    return a + frameFrac * (b - a);
}

static float renderSimdChunk4(const float* table,
                              int frameA,
                              int frameB,
                              int frameLength,
                              float frameFrac,
                              float rootHz,
                              const float* unisonHzRatio,
                              float invSampleRate,
                              float* phases) noexcept {
    alignas(16) float phaseLanes[4];
    alignas(16) float incLanes[4];
    for (int i = 0; i < 4; ++i) {
        phaseLanes[i] = phases[i];
        incLanes[i] = rootHz * unisonHzRatio[i] * invSampleRate;
    }

    SimdVec phaseVec = simdAdd(simdLoad(phaseLanes), simdLoad(incLanes));
    simdStore(phaseLanes, phaseVec);
    wrapPhases01(phaseLanes, 4);

    alignas(16) float sampleLanes[4];
    for (int i = 0; i < 4; ++i) {
        phases[i] = phaseLanes[i];
        sampleLanes[i] = gatherLerpLane(table, frameA, frameB, frameLength, phaseLanes[i], frameFrac);
    }
    return horizontalSum(simdLoad(sampleLanes));
}

#endif // AUDIOAPP_WAVETABLE_OSC_SIMD

} // namespace

bool renderWavetableUnisonBankSimd(const float* table,
                                   int frameCount,
                                   int frameLength,
                                   float frameIndex,
                                   float rootHz,
                                   const float* unisonHzRatio,
                                   int unisonCount,
                                   float invSampleRate,
                                   float* phases,
                                   float& sumOut) noexcept {
#if !AUDIOAPP_WAVETABLE_OSC_SIMD
    (void)table;
    (void)frameCount;
    (void)frameLength;
    (void)frameIndex;
    (void)rootHz;
    (void)unisonHzRatio;
    (void)unisonCount;
    (void)invSampleRate;
    (void)phases;
    (void)sumOut;
    return false;
#else
    if (table == nullptr || unisonHzRatio == nullptr || phases == nullptr ||
        frameCount <= 0 || frameLength <= 0 || unisonCount <= 0 ||
        unisonCount > kWavetableMaxUnison || invSampleRate <= 0.0f) {
        return false;
    }

    const float fi = std::clamp(frameIndex, 0.0f, static_cast<float>(frameCount - 1));
    const int frameA = static_cast<int>(fi);
    const int frameB = std::min(frameA + 1, frameCount - 1);
    const float frameFrac = fi - static_cast<float>(frameA);

    float sum = 0.0f;
    int u = 0;
    for (; u + 4 <= unisonCount; u += 4) {
        sum += renderSimdChunk4(table,
                                frameA,
                                frameB,
                                frameLength,
                                frameFrac,
                                rootHz,
                                unisonHzRatio + u,
                                invSampleRate,
                                phases + u);
    }
    for (; u < unisonCount; ++u) {
        phases[u] += rootHz * unisonHzRatio[u] * invSampleRate;
        if (phases[u] >= 1.0f || phases[u] < 0.0f) {
            phases[u] -= std::floor(phases[u]);
        }
        sum += gatherLerpLane(table, frameA, frameB, frameLength, phases[u], frameFrac);
    }

    sumOut = sum / static_cast<float>(unisonCount);
    return true;
#endif
}

} // namespace audioapp
