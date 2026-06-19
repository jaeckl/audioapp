#include "audioapp/MetallicNoiseSynth.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr double kTwoPi = 6.28318530718;

float xorshiftNoise(uint32_t& state) noexcept {
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    return static_cast<float>(state) * (1.0f / 2147483648.0f) - 1.0f;
}

uint32_t seedFromPitch(int pitch, uint32_t salt) noexcept {
    return 0x9E3779B9u ^ static_cast<uint32_t>(pitch) * 0x85EBCA6Bu ^ salt;
}

float expDecay(double t, float tau) noexcept {
    return static_cast<float>(std::exp(-t / static_cast<double>(tau)));
}

float centsToRatio(float cents) noexcept {
    return std::pow(2.0f, cents / 1200.0f);
}

float expFreq(float minHz, float maxHz, int index, int count, float randMul) noexcept {
    const float t = static_cast<float>(index) / static_cast<float>(count);
    const float ratio = t * 0.92f + 0.08f;
    return minHz * std::pow(maxHz / minHz, ratio) * randMul;
}

} // namespace

void triggerMetallicNoiseVoice(MetallicNoiseVoiceRuntime& voice,
                               int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseStateL = seedFromPitch(pitch, 0x1111u);
    voice.noiseStateR = seedFromPitch(pitch, 0x2222u);
    voice.cachedBrightNorm = -1.0f;
    voice.cachedSpreadNorm = -1.0f;
    voice.cachedSampleRate = 0.0f;

    for (int i = 0; i < kMetallicResonatorCount; ++i) {
        const uint32_t s = seedFromPitch(pitch, 0x4000u + static_cast<uint32_t>(i) * 97u);
        voice.resFreqRand[i] = 0.82f + (static_cast<float>(s & 0xFFFFu) / 65535.0f) * 0.36f;
    }
}

void updateResonatorBank(MetallicNoiseVoiceRuntime& voice,
                         const MetallicNoiseTimbre& timbre,
                         float brightNorm,
                         float spreadNorm,
                         float sampleRate) noexcept {
    if (sampleRate <= 0.0f) {
        return;
    }

    if (voice.cachedBrightNorm == brightNorm &&
        voice.cachedSpreadNorm == spreadNorm &&
        voice.cachedSampleRate == sampleRate) {
        return;
    }

    const float resQ =
        std::clamp(timbre.resQ * (0.55f + spreadNorm * 0.35f), 0.35f, 2.2f);
    const float resMin = timbre.resMinHz;
    const float resMax = std::min(timbre.resMaxHz + spreadNorm * 6000.0f,
                                  sampleRate * 0.42f);

    for (int i = 0; i < kMetallicResonatorCount; ++i) {
        const float baseFreq =
            expFreq(resMin, resMax, i, kMetallicResonatorCount, voice.resFreqRand[i]);
        const float freq = baseFreq * (1.0f + brightNorm * 0.15f);
        voice.resonators[i].freq = freq;
        cookSamplerBiquad(voice.resonators[i].coeffs, 2, sampleRate, freq, resQ);
    }

    const float bodyFreq = timbre.bodyHz * (1.0f + brightNorm * 0.25f);
    cookSamplerBiquad(voice.bodyBpfCoeffs, 2, sampleRate, bodyFreq, timbre.bodyQ);
    if (timbre.midWashAmount > 0.001f) {
        const float midHz = timbre.midWashHz * (1.0f + brightNorm * 0.12f);
        cookSamplerBiquad(voice.midWashCoeffs, 2, sampleRate, midHz, timbre.midWashQ);
    }

    voice.cachedBrightNorm = brightNorm;
    voice.cachedSpreadNorm = spreadNorm;
    voice.cachedSampleRate = sampleRate;
}

static float metallicSampleChannel(MetallicNoiseVoiceRuntime& voice,
                                   const MetallicNoiseTimbre& timbre,
                                   uint32_t& noiseState,
                                   BiquadState& lpState,
                                   BiquadState& hpState,
                                   BiquadState& bodyState,
                                   BiquadState& midWashState,
                                   BiquadState* resonatorStates,
                                   double sampleRate,
                                   float velocityGain,
                                   float outputGain) noexcept {
    const double t = voice.elapsedSec;
    const float ampEnv = expDecay(t, timbre.decaySec);
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float lpSweepHz = timbre.lpSweepEndHz +
        (timbre.lpSweepStartHz - timbre.lpSweepEndHz) * expDecay(t, timbre.lpSweepTau);
    const float lpHz = std::clamp(lpSweepHz, 100.0f, static_cast<float>(sampleRate * 0.45f));
    cookSamplerBiquad(voice.driverLpCoeffs, 0, static_cast<float>(sampleRate), lpHz, 0.707f);
    cookSamplerBiquad(voice.driverHpCoeffs, 1, static_cast<float>(sampleRate),
                      timbre.hpShimmerHz, 0.707f);

    const float raw = xorshiftNoise(noiseState);

    float driver = processBiquadSample(raw, voice.driverLpCoeffs, lpState);
    const float hpNoise = processBiquadSample(raw, voice.driverHpCoeffs, hpState);
    const float shimmerTau = std::max(timbre.decaySec * 0.75f, 0.06f);
    const float shimmerEnv = timbre.hpShimmerAmount * expDecay(t, shimmerTau);
    driver += hpNoise * shimmerEnv;

    const float resExciteRaw = std::clamp(timbre.resExciteRaw, 0.0f, 1.0f);
    const float resInput = driver * (1.0f - resExciteRaw) + raw * resExciteRaw;

    float resOut = 0.0f;
    if (timbre.resMix > 0.001f) {
        for (int i = 0; i < kMetallicResonatorCount; ++i) {
            const float band =
                processBiquadSample(resInput, voice.resonators[i].coeffs, resonatorStates[i]);
            resOut += band;
        }
        resOut = resOut / static_cast<float>(kMetallicResonatorCount) * timbre.resMix;
    }

    float bodyOut = 0.0f;
    if (timbre.bodyAmount > 0.001f) {
        bodyOut = processBiquadSample(raw, voice.bodyBpfCoeffs, bodyState) * timbre.bodyAmount;
    }

    float midWashOut = 0.0f;
    if (timbre.midWashAmount > 0.001f) {
        const float mid = processBiquadSample(raw, voice.midWashCoeffs, midWashState);
        midWashOut = mid * timbre.midWashAmount * expDecay(t, timbre.decaySec * 0.9f);
    }

    float thwack = 0.0f;
    if (timbre.thwackAmount > 0.001f && t < timbre.thwackDecaySec * 6.0f) {
        thwack = driver * expDecay(t, timbre.thwackDecaySec) * timbre.thwackAmount;
    }

    float crashBurst = 0.0f;
    if (timbre.crashNoiseMix > 0.001f && t < 0.55f) {
        crashBurst = driver * expDecay(t, 0.14f) * timbre.crashNoiseMix;
    }

    return (resOut + bodyOut + midWashOut + driver * timbre.driverMix + thwack + crashBurst) *
           ampEnv * velocityGain * outputGain;
}

float metallicNoiseSampleL(MetallicNoiseVoiceRuntime& voice,
                           const MetallicNoiseTimbre& timbre,
                           double sampleRate,
                           float velocityGain,
                           float outputGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    BiquadState resonatorStatesL[kMetallicResonatorCount];
    for (int i = 0; i < kMetallicResonatorCount; ++i) {
        resonatorStatesL[i] = voice.resonators[i].stateL;
    }

    const float out = metallicSampleChannel(
        voice, timbre, voice.noiseStateL,
        voice.driverLpStateL, voice.driverHpStateL,
        voice.bodyBpfStateL, voice.midWashStateL, resonatorStatesL,
        sampleRate, velocityGain, outputGain);

    for (int i = 0; i < kMetallicResonatorCount; ++i) {
        voice.resonators[i].stateL = resonatorStatesL[i];
    }
    return out;
}

float metallicNoiseSampleR(MetallicNoiseVoiceRuntime& voice,
                           const MetallicNoiseTimbre& timbre,
                           double sampleRate,
                           float velocityGain,
                           float outputGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    if (timbre.widthAmount > 0.01f && voice.cachedSampleRate > 0.0f) {
        const float detuneRatio = centsToRatio(timbre.widthDetuneCents * timbre.widthAmount);
        for (int i = 0; i < kMetallicResonatorCount; ++i) {
            const float f = std::clamp(voice.resonators[i].freq * detuneRatio,
                                       20.0f, voice.cachedSampleRate * 0.42f);
            cookSamplerBiquad(voice.resonators[i].coeffs, 2,
                              voice.cachedSampleRate, f,
                              timbre.resQ * (0.6f + voice.cachedSpreadNorm * 0.6f));
        }

        const float bodyFreq = timbre.bodyHz * (1.0f + voice.cachedBrightNorm * 0.25f) *
                               detuneRatio;
        cookSamplerBiquad(voice.bodyBpfCoeffs, 2,
                          voice.cachedSampleRate,
                          std::clamp(bodyFreq, 40.0f, voice.cachedSampleRate * 0.42f),
                          timbre.bodyQ);
    }

    BiquadState resonatorStatesR[kMetallicResonatorCount];
    for (int i = 0; i < kMetallicResonatorCount; ++i) {
        resonatorStatesR[i] = voice.resonators[i].stateR;
    }

    const float out = metallicSampleChannel(
        voice, timbre, voice.noiseStateR,
        voice.driverLpStateR, voice.driverHpStateR,
        voice.bodyBpfStateR, voice.midWashStateR, resonatorStatesR,
        sampleRate, velocityGain * (0.92f + timbre.widthAmount * 0.08f),
        outputGain);

    for (int i = 0; i < kMetallicResonatorCount; ++i) {
        voice.resonators[i].stateR = resonatorStatesR[i];
    }
    return out;
}

} // namespace audioapp
