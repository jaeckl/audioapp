#include "audioapp/SubtractiveOscSimd.hpp"

#include "audioapp/SubtractiveMorphTable.hpp"

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

#if AUDIOAPP_SUBTRACTIVE_OSC_SIMD

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
using SimdVec = float32x4_t;
using SimdMask = uint32x4_t;

static SimdVec simdSet1(float v) noexcept { return vdupq_n_f32(v); }

static SimdVec simdLoad(const float* p) noexcept { return vld1q_f32(p); }

static void simdStore(float* p, SimdVec v) noexcept { vst1q_f32(p, v); }

static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return vaddq_f32(a, b); }

static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return vsubq_f32(a, b); }

static SimdMask simdGe(SimdVec a, SimdVec b) noexcept {
    return vcgeq_f32(a, b);
}

static SimdVec simdSelect(SimdMask mask, SimdVec on, SimdVec off) noexcept {
    return vbslq_f32(mask, on, off);
}

#else

using SimdVec = __m128;
using SimdMask = __m128;

static SimdVec simdSet1(float v) noexcept { return _mm_set1_ps(v); }

static SimdVec simdLoad(const float* p) noexcept { return _mm_loadu_ps(p); }

static void simdStore(float* p, SimdVec v) noexcept { _mm_storeu_ps(p, v); }

static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return _mm_add_ps(a, b); }

static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return _mm_sub_ps(a, b); }

static SimdMask simdGe(SimdVec a, SimdVec b) noexcept {
    return _mm_cmpge_ps(a, b);
}

static SimdVec simdSelect(SimdMask mask, SimdVec on, SimdVec off) noexcept {
    return _mm_or_ps(_mm_and_ps(mask, on), _mm_andnot_ps(mask, off));
}

#endif

static SimdVec wrapPhases(SimdVec phases) noexcept {
    const SimdVec twoPi = simdSet1(kTwoPi);
    const SimdMask wrapMask = simdGe(phases, twoPi);
    return simdSub(phases, simdSelect(wrapMask, twoPi, simdSet1(0.0f)));
}

#endif // AUDIOAPP_SUBTRACTIVE_OSC_SIMD

} // namespace

bool renderOscBankNoSyncSimd(float shape,
                             float rootHz,
                             float sampleRate,
                             const float* phaseIncPerUnit,
                             int unisonCount,
                             float level,
                             float* phases,
                             bool* wrappedOut,
                             float& sumOut) noexcept {
#if !AUDIOAPP_SUBTRACTIVE_OSC_SIMD
    (void)shape;
    (void)rootHz;
    (void)sampleRate;
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

    phaseVec = simdAdd(phaseVec, incVec);
    const SimdMask wrapMask = simdGe(phaseVec, simdSet1(kTwoPi));
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

    const auto& table = SubtractiveMorphTable::instance();
    const auto morph = table.prepareLookup(shape, table.pickMip(rootHz, sampleRate));
    float sum = 0.0f;
    for (int u = 0; u < unisonCount; ++u) {
        sum += table.lookupPrepared(morph, phaseLanes[u]);
    }
    sumOut = (sum / static_cast<float>(unisonCount)) * level;
    return true;
#endif
}

} // namespace audioapp
