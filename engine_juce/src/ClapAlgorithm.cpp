#include "audioapp/ClapAlgorithm.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

float clapNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

float clapAmpDecaySec(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 0.12f + (1.0f - clamped) * 0.38f;
}

} // namespace

float clapGeneratorSample(ClapVoiceRuntime& voice,
                          const ClapGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float toneNorm = std::clamp(params.clapTone, 0.0f, 1.0f);
    const float roomNorm = std::clamp(params.clapRoom, 0.0f, 1.0f);
    const float ampDecaySec =
        clapAmpDecaySec(params.clapDecay) * (0.7f + roomNorm * 0.8f);

    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float burstDecaySec = 0.04f + roomNorm * 0.14f;
    const float bpCenter = 800.0f + toneNorm * 3200.0f;
    float sample = 0.0f;

    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const double localT = t - static_cast<double>(voice.burstOffsets[i]);
        if (localT < 0.0 || localT > 0.25) {
            continue;
        }
        const float env = static_cast<float>(std::exp(-localT / burstDecaySec));
        const float noise = clapNoiseSample(voice.noiseSeed);
        const float ring =
            noise * std::sin(static_cast<float>(2.0 * 3.14159265358979323846 * bpCenter * localT));
        sample += ring * env * (0.55f + toneNorm * 0.35f);
    }

    return sample * ampEnv * velocityGain * params.gain * kInstrumentOutputGain;
}

void triggerClapVoice(ClapVoiceRuntime& voice,
                      float velocity,
                      const ClapGeneratorParams& params) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.velocity = velocity;
    voice.noiseSeed = 0.33f;
    const float spreadNorm = std::clamp(params.clapSpread, 0.0f, 1.0f);
    const float burstsNorm = std::clamp(params.clapBursts, 0.0f, 1.0f);
    voice.burstCount = 2 + static_cast<int>(std::lround(burstsNorm * 3.0f));
    const float interval = 0.008f + (1.0f - spreadNorm) * 0.010f;
    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const float jitter =
            (clapNoiseSample(voice.noiseSeed) * 0.5f + 0.5f) * spreadNorm * 0.004f;
        voice.burstOffsets[i] = static_cast<float>(i) * interval + jitter;
    }
}

} // namespace audioapp