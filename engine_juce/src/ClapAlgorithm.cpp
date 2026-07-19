#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/PercussionPitch.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {
float noise(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return seed / 1073741823.5f - 1.0f;
}

void configure(ClapVoiceRuntime& voice, float tone, float ratio,
               float sampleRate) noexcept {
    if (voice.configuredTone == tone &&
        voice.configuredPitchRatio == ratio &&
        voice.configuredSampleRate == sampleRate) return;
    // Wide tone/pitch spans so knobs are obviously audible (not just a mild
    // filter nudge on a short burst).
    const float palmHz =
        std::clamp((350.0f + tone * 4200.0f) * ratio, 80.0f, sampleRate * 0.42f);
    const float airHz =
        std::clamp((500.0f + tone * 7000.0f) * ratio, 120.0f, sampleRate * 0.42f);
    cookSamplerBiquad(voice.palmCoeffs, 2, sampleRate, palmHz,
                      0.45f + tone * 0.85f);
    cookSamplerBiquad(voice.airCoeffs, 1, sampleRate, airHz, 0.707f);
    voice.palmState = {};
    voice.airState = {};
    voice.configuredTone = tone;
    voice.configuredPitchRatio = ratio;
    voice.configuredSampleRate = sampleRate;
}
} // namespace

float clapGeneratorSample(ClapVoiceRuntime& voice, const ClapGeneratorParams& params,
                          double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float tone = std::clamp(params.clapTone, 0.0f, 1.0f);
    const float room = std::clamp(params.clapRoom, 0.0f, 1.0f);
    const float decay = std::clamp(params.clapDecay, 0.0f, 1.0f);
    const float ratio = percussionPitchRatio(params.clapPitch, voice.pitch, 39,
                                             params.clapKeyTrack);
    configure(voice, tone, ratio, static_cast<float>(sampleRate));
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

    // Tone steers palm vs air; high tone = bright/hissy, low = woody palm.
    const float palmMix = 0.85f - tone * 0.45f;
    const float airMix = 0.15f + tone * 0.55f;
    float out = palm * burstEnv * (0.30f + tone * 0.55f) +
                (palm * palmMix + air * airMix) * tailEnv;
    out = std::tanh(out * (1.35f + room * 0.45f)) * 0.72f;
    return out * velocityGain * params.gain * kInstrumentOutputGain * 1.45f;
}

void triggerClapVoice(ClapVoiceRuntime& voice, int pitch, float velocity,
                      const ClapGeneratorParams& params) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1; voice.pitch = pitch; voice.velocity = velocity; voice.noiseSeed = 0.33f;
    voice.configuredTone = -1.0f;
    voice.configuredPitchRatio = -1.0f;
    const float spread = std::clamp(params.clapSpread, 0.0f, 1.0f);
    voice.burstCount = 2 + static_cast<int>(std::lround(
        std::clamp(params.clapBursts, 0.0f, 1.0f) * 3.0f));
    // Pitch also tightens/loosens burst spacing so the knob isn't filter-only.
    const float ratio = std::max(0.25f, percussionPitchRatio(
        params.clapPitch, pitch, 39, params.clapKeyTrack));
    const float interval = (0.008f + spread * 0.012f) / std::sqrt(ratio);
    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const float jitter = noise(voice.noiseSeed) * spread * 0.0025f;
        voice.burstOffsets[i] = std::max(0.0f, i * interval + jitter);
    }
}

} // namespace audioapp
