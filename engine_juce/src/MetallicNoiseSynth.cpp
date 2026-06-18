#include "audioapp/MetallicNoiseSynth.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr double kTwoPi = 6.28318530718;

float noiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

float expDecay(double t, float tau) noexcept {
    return static_cast<float>(std::exp(-t / static_cast<double>(tau)));
}

} // namespace

void triggerMetallicNoiseVoice(MetallicNoiseVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseSeed = 0.15f + static_cast<float>(pitch) * 0.009f;
}

void updateMetallicNoiseBandFilters(MetallicNoiseVoiceRuntime& voice,
                                    float hpHz,
                                    float metalNorm,
                                    float sampleRate) noexcept {
    if (sampleRate <= 0.0f) {
        return;
    }

    cookSamplerBiquad(voice.hpCoeffs, 1, sampleRate, hpHz, 0.707f);

    const float q = 1.2f + metalNorm * 2.2f;
    for (int i = 0; i < kMetallicNoiseBandCount; ++i) {
        const float ratio = 1.18f + static_cast<float>(i) * (0.31f + metalNorm * 0.42f);
        const float bpfHz = std::clamp(hpHz * ratio, 200.0f, sampleRate * 0.42f);
        cookSamplerBiquad(voice.bandCoeffs[i], 2, sampleRate, bpfHz, q);
    }
}

float metallicNoiseSample(MetallicNoiseVoiceRuntime& voice,
                          const MetallicNoiseTimbre& timbre,
                          double sampleRate,
                          float velocityGain,
                          float outputGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float metalNorm = std::clamp(timbre.metalNorm, 0.0f, 1.0f);
    const float brightNorm = std::clamp(timbre.brightNorm, 0.0f, 1.0f);
    const float chokeNorm = std::clamp(timbre.chokeNorm, 0.0f, 1.0f);

    float ampDecaySec =
        timbre.minDecaySec + (1.0f - std::clamp(timbre.decayNorm, 0.0f, 1.0f)) *
                                 (timbre.maxDecaySec - timbre.minDecaySec);
    ampDecaySec *= 1.0f - chokeNorm * 0.55f;

    const double t = voice.elapsedSec;
    const float ampEnv = expDecay(t, ampDecaySec);
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float hpStart = timbre.hpStartHz + brightNorm * 4000.0f;
    const float hpEnd = timbre.hpEndHz + brightNorm * 1800.0f;
    const float sweepTau = timbre.sweepTauSec * (0.65f + (1.0f - metalNorm) * 0.8f);
    const float hpHz = hpEnd + (hpStart - hpEnd) * expDecay(t, sweepTau);

    updateMetallicNoiseBandFilters(voice, hpHz, metalNorm, static_cast<float>(sampleRate));

    const float raw = noiseSample(voice.noiseSeed);
    float wash = processBiquadSample(raw, voice.hpCoeffs, voice.hpState) * timbre.washGain;

    for (int i = 0; i < kMetallicNoiseBandCount; ++i) {
        const float band =
            processBiquadSample(raw, voice.bandCoeffs[i], voice.bandStates[i]);
        const float weight = (0.22f + metalNorm * 0.18f) / static_cast<float>(i + 1);
        wash += band * weight;
    }

    float attack = 0.0f;
    if (t < 0.006) {
        attack = raw * expDecay(t, timbre.attackTauSec) * timbre.attackGain *
                 (0.35f + brightNorm * 0.65f);
    }

    const float sample = (wash + attack) * ampEnv * velocityGain * outputGain;
    return sample;
}

} // namespace audioapp
