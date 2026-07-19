#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/PercussionPitch.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {
// Classic 808 clap: white noise → BP ~1 kHz (low Q) → multi-pulse + room.
// Pitch/KeyTrack move MAIN BP only. No high-Q resonator / air band / sine.
constexpr float kClapBpBaseHz = 1000.0f;

// Integer LCG — float Park-Miller (fmod*16807) collapses to HF tones (~1.5/4.5 kHz).
float noise(uint32_t& seed) noexcept {
    seed = seed * 1664525u + 1013904223u;
    return static_cast<float>(static_cast<int32_t>(seed)) * (1.0f / 2147483648.0f);
}

void configure(ClapVoiceRuntime& voice, float tone, float ratio,
               float sampleRate) noexcept {
    if (voice.configuredTone == tone &&
        voice.configuredPitchRatio == ratio &&
        voice.configuredSampleRate == sampleRate) return;

    const float nyquistCap = sampleRate * 0.42f;
    const float r = std::clamp(ratio, 0.45f, 2.2f);
    const float centerHz = std::clamp(
        kClapBpBaseHz * r * (0.92f + tone * 0.16f),
        700.0f, std::min(1700.0f, nyquistCap));
    const float q = 0.85f + tone * 0.40f; // ~0.85–1.25 — wide clap BP
    cookSamplerBiquad(voice.bpCoeffs, 2, sampleRate, centerHz, q);
    // Fixed gentle LP tames hiss; NOT pitch-linked.
    cookSamplerBiquad(voice.lpCoeffs, 0, sampleRate, 4500.0f, 0.707f);
    voice.bpState = {};
    voice.lpState = {};
    voice.bodyHz = centerHz;
    voice.configuredTone = tone;
    voice.configuredPitchRatio = ratio;
    voice.configuredSampleRate = sampleRate;
}

float sawCrackPulse(double local, float fallSec) noexcept {
    if (local < 0.0 || local >= static_cast<double>(fallSec)) return 0.0f;
    const float rise = 0.0006f;
    if (local < static_cast<double>(rise)) {
        return static_cast<float>(local / rise);
    }
    const float t = static_cast<float>(local) - rise;
    const float fall = std::max(fallSec - rise, 0.002f);
    return std::max(0.0f, 1.0f - t / fall);
}
} // namespace

float clapGeneratorSample(ClapVoiceRuntime& voice, const ClapGeneratorParams& params,
                          double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float tone = std::clamp(params.clapTone, 0.0f, 1.0f);
    const float room = std::clamp(params.clapRoom, 0.0f, 1.0f);
    const float decay = std::clamp(params.clapDecay, 0.0f, 1.0f);
    const float ratio = percussionPitchRatio(
        params.clapPitch, voice.pitch, 39, params.clapKeyTrack);
    configure(voice, tone, ratio, static_cast<float>(sampleRate));

    const double t = voice.elapsedSec;
    const float raw = noise(voice.noiseSeed);
    // Mild pink tilt — less HF hiss, still broadband crack.
    voice.noiseLp += 0.18f * (raw - voice.noiseLp);
    const float band =
        processBiquadSample(voice.noiseLp, voice.bpCoeffs, voice.bpState);
    const float filtered =
        processBiquadSample(band, voice.lpCoeffs, voice.lpState);

    float crackEnv = 0.0f;
    const float shortFall = 0.009f + (1.0f - tone) * 0.005f;
    const int n = std::min(voice.burstCount, 5);
    for (int i = 0; i < n; ++i) {
        const bool last = (i == n - 1);
        const float fall = last ? (0.018f + decay * 0.012f) : shortFall;
        const float weight = last ? 0.85f : (1.0f - i * 0.14f);
        crackEnv += sawCrackPulse(t - voice.burstOffsets[i], fall) * weight;
    }
    crackEnv = std::min(crackEnv, 1.35f);

    const float roomTau = 0.055f + decay * 0.18f + room * 0.12f;
    const float roomEnv =
        static_cast<float>(std::exp(-t / std::max(roomTau, 0.01f))) *
        (0.12f + room * 0.40f) *
        (t < 0.008 ? static_cast<float>(t / 0.008) : 1.0f);

    if (crackEnv < 0.0001f && roomEnv < 0.00005f && t > 0.20) {
        voice.active = 0;
        return 0.0f;
    }

    float out = filtered * (crackEnv * 1.20f + roomEnv);
    out = std::tanh(out * 1.35f) * 0.85f;
    return out * velocityGain * params.gain * kInstrumentOutputGain * 1.15f;
}

void triggerClapVoice(ClapVoiceRuntime& voice, int pitch, float velocity,
                      const ClapGeneratorParams& params) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseSeed = 0xA341316Cu ^ static_cast<uint32_t>(pitch * 2654435761u);
    voice.noiseLp = 0.0f;
    voice.configuredTone = -1.0f;
    voice.configuredPitchRatio = -1.0f;
    voice.bodyHz = kClapBpBaseHz;
    const float spread = std::clamp(params.clapSpread, 0.0f, 1.0f);
    voice.burstCount = 2 + static_cast<int>(std::lround(
        std::clamp(params.clapBursts, 0.0f, 1.0f) * 3.0f));
    const float baseInterval = 0.009f + spread * 0.009f;
    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const float jitter = noise(voice.noiseSeed) * spread * 0.0015f;
        voice.burstOffsets[i] = std::max(0.0f, i * baseInterval + jitter);
    }
}

} // namespace audioapp
