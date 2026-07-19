#include "audioapp/PhaseModOscSimd.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define AUDIOAPP_PHASEMOD_OSC_SIMD 1
#elif defined(_M_X64) || defined(_M_IX86) || defined(__SSE__)
#include <xmmintrin.h>
#define AUDIOAPP_PHASEMOD_OSC_SIMD 1
#endif

namespace audioapp {
namespace {

constexpr float kPi = 3.14159265358979323846f;
constexpr float kTwoPi = 6.28318530718f;

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

#if AUDIOAPP_PHASEMOD_OSC_SIMD

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
using SimdVec = float32x4_t;
using SimdMask = uint32x4_t;

static SimdVec simdSet1(float v) noexcept { return vdupq_n_f32(v); }
static SimdVec simdLoad(const float* p) noexcept { return vld1q_f32(p); }
static void simdStore(float* p, SimdVec v) noexcept { vst1q_f32(p, v); }
static SimdVec simdAdd(SimdVec a, SimdVec b) noexcept { return vaddq_f32(a, b); }
static SimdVec simdSub(SimdVec a, SimdVec b) noexcept { return vsubq_f32(a, b); }
static SimdVec simdMul(SimdVec a, SimdVec b) noexcept { return vmulq_f32(a, b); }
static SimdMask simdGe(SimdVec a, SimdVec b) noexcept { return vcgeq_f32(a, b); }
static SimdMask simdLt(SimdVec a, SimdVec b) noexcept { return vcltq_f32(a, b); }
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
static SimdVec simdMul(SimdVec a, SimdVec b) noexcept { return _mm_mul_ps(a, b); }
static SimdMask simdGe(SimdVec a, SimdVec b) noexcept { return _mm_cmpge_ps(a, b); }
static SimdMask simdLt(SimdVec a, SimdVec b) noexcept { return _mm_cmplt_ps(a, b); }
static SimdVec simdSelect(SimdMask mask, SimdVec on, SimdVec off) noexcept {
    return _mm_or_ps(_mm_and_ps(mask, on), _mm_andnot_ps(mask, off));
}

#endif

static SimdVec wrapPhasesTwoPi(SimdVec phases) noexcept {
    const SimdVec twoPi = simdSet1(kTwoPi);
    return simdSub(phases, simdSelect(simdGe(phases, twoPi), twoPi, simdSet1(0.0f)));
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
        return simdSelect(simdLt(t, one), triA, triB);
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
    return simdAdd(simdMul(a, simdSet1(1.0f - t)), simdMul(b, simdSet1(t)));
}

static float waveSampleScalar(int wave, float phase) noexcept {
    const float wrapped = std::fmod(phase, kTwoPi);
    switch (wave) {
    case 0:
        return std::sin(wrapped);
    case 1: {
        const float t = wrapped / kPi;
        return t <= 1.0f ? (2.0f * t - 1.0f) : (3.0f - 2.0f * t);
    }
    case 2:
        return (1.0f / kPi) * (wrapped - kPi);
    case 3:
        return wrapped < kPi ? 1.0f : -1.0f;
    case 4:
    default:
        return wrapped < kPi ? 1.0f : -0.2f;
    }
}

static float morphWaveSampleScalar(float shape, float phase) noexcept {
    const float scaled = safe_clamp(shape, 0.0f, 1.0f) * 4.0f;
    const int i0 = std::min(4, static_cast<int>(scaled));
    const int i1 = std::min(4, i0 + 1);
    const float t = scaled - static_cast<float>(i0);
    const float a = waveSampleScalar(i0, phase);
    if (i0 == i1 || t <= 0.0f) {
        return a;
    }
    return a * (1.0f - t) + waveSampleScalar(i1, phase) * t;
}

#endif // AUDIOAPP_PHASEMOD_OSC_SIMD

} // namespace

bool renderPhaseModUnisonOpSimd(float shape,
                                float level,
                                float opHz,
                                const float* phaseIncs,
                                float* phases,
                                const float* modPhases,
                                int unisonCount,
                                float* outSamples) noexcept {
#if !AUDIOAPP_PHASEMOD_OSC_SIMD
    (void)shape;
    (void)level;
    (void)opHz;
    (void)phaseIncs;
    (void)phases;
    (void)modPhases;
    (void)unisonCount;
    (void)outSamples;
    return false;
#else
    if (phaseIncs == nullptr || phases == nullptr || modPhases == nullptr ||
        outSamples == nullptr || unisonCount <= 0 || unisonCount > kPhaseModMaxUnison) {
        return false;
    }

    int u = 0;
    for (; u + 4 <= unisonCount; u += 4) {
        alignas(16) float phaseLanes[4];
        alignas(16) float incLanes[4];
        alignas(16) float modLanes[4];
        for (int i = 0; i < 4; ++i) {
            phaseLanes[i] = phases[u + i];
            incLanes[i] = opHz * phaseIncs[u + i];
            modLanes[i] = modPhases[u + i];
        }

        SimdVec phaseVec = simdAdd(simdLoad(phaseLanes), simdLoad(incLanes));
        phaseVec = wrapPhasesTwoPi(phaseVec);
        simdStore(phaseLanes, phaseVec);
        for (int i = 0; i < 4; ++i) {
            phases[u + i] = phaseLanes[i];
        }

        phaseVec = simdAdd(phaseVec, simdLoad(modLanes));
        SimdVec samples = morphWaveSampleSimd(shape, phaseVec);
        samples = simdMul(samples, simdSet1(level));
        alignas(16) float sampleLanes[4];
        simdStore(sampleLanes, samples);
        for (int i = 0; i < 4; ++i) {
            outSamples[u + i] = sampleLanes[i];
        }
    }

    for (; u < unisonCount; ++u) {
        phases[u] += opHz * phaseIncs[u];
        if (phases[u] >= kTwoPi) {
            phases[u] -= kTwoPi;
        }
        const float phase = phases[u] + modPhases[u];
        outSamples[u] = morphWaveSampleScalar(shape, phase) * level;
    }
    return true;
#endif
}

} // namespace audioapp
