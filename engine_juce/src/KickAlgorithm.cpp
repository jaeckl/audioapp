#include "audioapp/KickAlgorithm.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr double kTwoPi = 6.28318530718;

float kickNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

} // namespace

float normalizedToAmpDecaySec(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 0.08f + (1.0f - clamped) * 0.42f;
}

float drumMidiKeyTrackRatio(int pitch, int referencePitch, float keyTrackNorm) noexcept {
    if (keyTrackNorm < 0.5f) {
        return 1.0f;
    }
    return std::pow(2.0f, static_cast<float>(pitch - referencePitch) / 12.0f);
}

float kickGeneratorSample808(KickVoiceRuntime& voice,
                             const KickGeneratorParams& params,
                             double sampleRate,
                             float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float pitchNorm = std::clamp(params.kickPitch, 0.0f, 1.0f);
    const float punchNorm = std::clamp(params.kickPunch, 0.0f, 1.0f);
    const float clickNorm = std::clamp(params.kickClick, 0.0f, 1.0f);
    const float toneNorm = std::clamp(params.kickTone, 0.0f, 1.0f);

    const float startHz = 80.0f + pitchNorm * 120.0f;
    const float endHz = 35.0f + (1.0f - punchNorm) * 25.0f;
    const float pitchDecaySec = 0.04f + (1.0f - punchNorm) * 0.12f;
    const float ampDecaySec = normalizedToAmpDecaySec(params.kickDecay);

    const float tuneRatio =
        drumMidiKeyTrackRatio(voice.pitch, 36, params.kickKeyTrack);
    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float currentHz =
        (endHz + (startHz - endHz) * static_cast<float>(std::exp(-t / pitchDecaySec))) *
        tuneRatio;
    voice.phase += static_cast<float>(kTwoPi * currentHz / sampleRate);
    if (voice.phase >= static_cast<float>(kTwoPi)) {
        voice.phase -= static_cast<float>(kTwoPi);
    }

    const float drive = 1.0f + toneNorm * 3.0f;
    float body = std::sin(voice.phase);
    body = std::tanh(body * drive);

    float click = 0.0f;
    if (clickNorm > 0.001f && t < 0.004) {
        click = kickNoiseSample(voice.noiseSeed) *
                static_cast<float>(std::exp(-t / 0.0015)) * clickNorm;
    }

    const float sample = (body * (1.0f - clickNorm * 0.35f) + click) * ampEnv * velocityGain;
    return sample * params.gain * kInstrumentOutputGain;
}

int kickModelIndex(float kickModel) noexcept {
    return std::clamp(static_cast<int>(std::lround(kickModel * 2.0f)), 0, 2);
}

float kickGeneratorSample(KickVoiceRuntime& voice,
                          const KickGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept {
    switch (kickModelIndex(params.kickModel)) {
        case 0:
        default:
            return kickGeneratorSample808(voice, params, sampleRate, velocityGain);
    }
}

void triggerKickVoice(KickVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseSeed = 0.123f;
}

} // namespace audioapp