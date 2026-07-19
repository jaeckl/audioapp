#include "audioapp/SubtractiveOscSimd.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define AUDIOAPP_SUBTRACTIVE_OSC_SIMD 1
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
#include <xmmintrin.h>
#define AUDIOAPP_SUBTRACTIVE_OSC_SIMD 1
#endif

namespace audioapp {
namespace {

constexpr float kTwoPi = 6.28318530718f;
constexpr float kPi = 3.14159265358979323846f;

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

#if AUDIOAPP_SUBTRACTIVE_OSC_SIMD

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
using SimdVec = float32x4_t;
using SimdMask = uint32x4_t;

static SimdVec simdSet1(float v) noexcept { return vdupq_n_f32(v); }

static SimdVec simdLoad(const float* p) noexcept { return vld1q_f32(p); }

static void simdStore(float* p, SimdVec v) noexcept { vst1q_f32(p, v); }

static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return vaddq_f32(a, b); }

static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return vsubq_f32(a, b); }

static SimdVec simdMul(SimdVec a, SimdVec b) noexcept { return vmulq_f32(a, b); }

static SimdMask simdGe(SimdVec a, SimdVec b) noexcept {
    return vcgeq_f32(a, b);
}

static SimdMask simdLt(SimdVec a, SimdVec b) noexcept {
    return vcltq_f32(a, b);
}

static SimdVec simdSelect(SimdMask mask, SimdVec on, SimdVec off) noexcept {
    return vbslq_f32(mask, on, off);
}

static float horizontalSum(SimdVec v) noexcept {
    const float32x2_t low = vget_low_f32(v);
    const float32x2_t high = vget_high_f32(v);
    const float32x2_t sum2 = vadd_f32(low, high);
    return vget_lane_f32(vpadd_f32(sum2, sum2), 0);
}

#else

using SimdVec = __m128;
using SimdMask = __m128;

static SimdVec simdSet1(float v) noexcept { return _mm_set1_ps(v); }

static SimdVec simdLoad(const float* p) noexcept { return _mm_loadu_ps(p); }

static void simdStore(float* p, SimdVec v) noexcept { _mm_storeu_ps(p, v); }

static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return _mm_add_ps(a, b); }

static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return _mm_sub_ps(a, b); }

static SimdVec simdMul(SimdVec a, SimdVec b) noexcept { return _mm_mul_ps(a, b); }

static SimdMask simdGe(SimdVec a, SimdVec b) noexcept {
    return _mm_cmpge_ps(a, b);
}

static SimdMask simdLt(SimdVec a, SimdVec b) noexcept {
    return _mm_cmplt_ps(a, b);
}

static SimdVec simdSelect(SimdMask mask, SimdVec on, SimdVec off) noexcept {
    return _mm_or_ps(_mm_and_ps(mask, on), _mm_andnot_ps(mask, off));
}

static float horizontalSum(SimdVec v) noexcept {
    alignas(16) float lanes[4];
    _mm_storeu_ps(lanes, v);
    return lanes[0] + lanes[1] + lanes[2] + lanes[3];
}

#endif

static SimdVec wrapPhases(SimdVec phases) noexcept {
    const SimdVec twoPi = simdSet1(kTwoPi);
    const SimdMask wrapMask = simdGe(phases, twoPi);
    return simdSub(phases, simdSelect(wrapMask, twoPi, simdSet1(0.0f)));
}

static SimdVec waveSampleSimd(int wave, SimdVec phase) noexcept {
    const SimdVec pi = simdSet1(kPi);
    const SimdVec one = simdSet1(1.0f);
    const SimdVec negOne = simdSet1(-1.0f);

    switch (wave) {
    case 0: {
        alignas(16) float phases[4];
        alignas(16) float out[4];
        simdStore(phases, phase);
        for (int i = 0; i < 4; ++i) {
            out[i] = std::sin(phases[i]);
        }
        return simdLoad(out);
    }
    case 1: {
        const SimdVec t = simdMul(phase, simdSet1(1.0f / kPi));
        const SimdVec triA = simdSub(simdMul(t, simdSet1(2.0f)), one);
        const SimdVec triB = simdSub(simdSet1(3.0f), simdMul(t, simdSet1(2.0f)));
        return simdSelect(simdLt(t, simdSet1(1.0f)), triA, triB);
    }
    case 2:
        return simdMul(simdSub(phase, pi), simdSet1(1.0f / kPi));
    case 3:
        return simdSelect(simdLt(phase, pi), one, negOne);
    case 4:
    default:
        return simdSelect(simdLt(phase, pi), one, simdSet1(-0.2f));
    }
}

static SimdVec morphWaveSampleSimd(float shape, SimdVec phase) noexcept {
    const float scaled = safe_clamp(shape, 0.0f, 1.0f) * 4.0f;
    const int i0 = std::min(4, static_cast<int>(scaled));
    const int i1 = std::min(4, i0 + 1);
    const float t = scaled - static_cast<float>(i0);
    const SimdVec a = waveSampleSimd(i0, phase);
    if (i0 == i1 || t <= 0.0f) {
        return a;
    }
    const SimdVec b = waveSampleSimd(i1, phase);
    const SimdVec oneMinusT = simdSet1(1.0f - t);
    const SimdVec tVec = simdSet1(t);
    return simdAdd(simdMul(a, oneMinusT), simdMul(b, tVec));
}

#endif // AUDIOAPP_SUBTRACTIVE_OSC_SIMD

} // namespace

bool renderOscBankNoSyncSimd(float shape,
                             float rootHz,
                             const float* phaseIncPerUnit,
                             int unisonCount,
                             float level,
                             float* phases,
                             bool* wrappedOut,
                             float& sumOut) noexcept {
#if !AUDIOAPP_SUBTRACTIVE_OSC_SIMD
    (void)shape;
    (void)rootHz;
    (void)phaseIncPerUnit;
    (void)unisonCount;
    (void)level;
    (void)phases;
    (void)wrappedOut;
    (void)sumOut;
    return false;
#else
    if (level <= 0.0f || unisonCount <= 0 || phaseIncPerUnit == nullptr || phases == nullptr) {
        return false;
    }
    if (unisonCount > kSubtractiveMaxUnison) {
        return false;
    }

    alignas(16) float phaseLanes[4]{};
    alignas(16) float incLanes[4]{};
    for (int u = 0; u < unisonCount; ++u) {
        phaseLanes[u] = phases[u];
        incLanes[u] = rootHz * phaseIncPerUnit[u];
    }

    SimdVec phaseVec = simdLoad(phaseLanes);
    const SimdVec incVec = simdLoad(incLanes);
    const SimdVec twoPi = simdSet1(kTwoPi);

    phaseVec = simdAdd(phaseVec, incVec);
    const SimdMask wrapMask = simdGe(phaseVec, twoPi);
    phaseVec = wrapPhases(phaseVec);
    simdStore(phaseLanes, phaseVec);

    if (wrappedOut != nullptr) {
        alignas(16) float wrapLanes[4];
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
        vst1q_f32(wrapLanes, vreinterpretq_f32_u32(wrapMask));
#else
        _mm_storeu_ps(wrapLanes, wrapMask);
#endif
        for (int u = 0; u < unisonCount; ++u) {
            wrappedOut[u] = wrapLanes[u] != 0.0f;
        }
    }

    for (int u = 0; u < unisonCount; ++u) {
        phases[u] = phaseLanes[u];
    }

    const SimdVec samples = morphWaveSampleSimd(shape, phaseVec);
    alignas(16) float sampleLanes[4];
    simdStore(sampleLanes, samples);

    float sum = 0.0f;
    for (int u = 0; u < unisonCount; ++u) {
        sum += sampleLanes[u];
    }
    sumOut = (sum / static_cast<float>(unisonCount)) * level;
    return true;
#endif
}

} // namespace audioapp
