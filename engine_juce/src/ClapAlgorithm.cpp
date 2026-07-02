#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {
float noise(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return seed / 1073741823.5f - 1.0f;
}
void configure(ClapVoiceRuntime& voice, float tone, float sampleRate) noexcept {
    if (voice.configuredTone == tone && voice.configuredSampleRate == sampleRate) return;
    cookSamplerBiquad(voice.palmCoeffs, 2, sampleRate, 900.0f + tone * 1900.0f,
                      0.62f + tone * 0.28f);
    cookSamplerBiquad(voice.airCoeffs, 1, sampleRate, 650.0f + tone * 1500.0f, 0.707f);
    voice.configuredTone = tone; voice.configuredSampleRate = sampleRate;
}
} // namespace

float clapGeneratorSample(ClapVoiceRuntime& voice, const ClapGeneratorParams& params,
                          double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float tone = std::clamp(params.clapTone, 0.0f, 1.0f);
    const float room = std::clamp(params.clapRoom, 0.0f, 1.0f);
    const float decay = std::clamp(params.clapDecay, 0.0f, 1.0f);
    configure(voice, tone, static_cast<float>(sampleRate));
    const double t = voice.elapsedSec;
    const float raw = noise(voice.noiseSeed);
    const float palm = processBiquadSample(raw, voice.palmCoeffs, voice.palmState);
    const float air = processBiquadSample(raw, voice.airCoeffs, voice.airState);

    float burstEnv = 0.0f;
    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const double local = t - voice.burstOffsets[i];
        if (local >= 0.0 && local < 0.035)
            burstEnv += static_cast<float>(std::exp(-local / (0.0035 + i * 0.0007)));
    }
    const float tailStart = 0.018f + voice.burstCount * 0.008f;
    const float tailT = std::max(0.0f, static_cast<float>(t) - tailStart);
    const float tailTau = 0.10f + decay * 0.48f;
    const float tailGate = static_cast<float>(t) >= tailStart ? 1.0f : 0.0f;
    const float tailEnv = tailGate * std::exp(-tailT / tailTau) * (0.12f + room * 0.48f);
    if (burstEnv + tailEnv < 0.00001f && t > 0.08) { voice.active = 0; return 0.0f; }

    float out = palm * burstEnv * (0.42f + tone * 0.18f) +
                (palm * 0.68f + air * 0.32f) * tailEnv;
    out = std::tanh(out * (1.35f + room * 0.45f)) * 0.72f;
    return out * velocityGain * params.gain * kInstrumentOutputGain * 1.45f;
}

void triggerClapVoice(ClapVoiceRuntime& voice, float velocity,
                      const ClapGeneratorParams& params) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1; voice.velocity = velocity; voice.noiseSeed = 0.33f;
    voice.configuredTone = -1.0f;
    const float spread = std::clamp(params.clapSpread, 0.0f, 1.0f);
    voice.burstCount = 2 + static_cast<int>(std::lround(
        std::clamp(params.clapBursts, 0.0f, 1.0f) * 3.0f));
    const float interval = 0.008f + spread * 0.010f;
    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const float jitter = noise(voice.noiseSeed) * spread * 0.0025f;
        voice.burstOffsets[i] = std::max(0.0f, i * interval + jitter);
    }
}

} // namespace audioapp
