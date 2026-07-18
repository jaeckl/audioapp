#include "audioapp/CrashAlgorithm.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/PercussionPitch.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {

constexpr float kTwoPi = 6.28318530718f;
constexpr float kModeRatio[kCrashModeCount] = {
    1.00f, 1.34f, 1.73f, 2.11f, 2.64f, 3.40f, 4.40f, 5.70f,
    7.30f, 9.40f, 12.0f, 15.0f, 19.0f, 24.0f, 30.0f, 38.0f};
constexpr float kStereoShape[kCrashModeCount] = {
    0.00f, 0.83f, -0.93f, 0.22f, 0.68f, -0.98f, 0.43f, 0.50f,
    -0.99f, 0.61f, 0.31f, -0.96f, 0.77f, 0.08f, -0.86f, 0.89f};

float noise(uint32_t& state) noexcept {
    state ^= state << 13; state ^= state >> 17; state ^= state << 5;
    return static_cast<float>(state) * (1.0f / 2147483648.0f) - 1.0f;
}

float decaySeconds(float norm, int mode) noexcept {
    const float base = mode == 2 ? 0.85f : (mode == 1 ? 0.70f : 0.55f);
    return base + norm * (mode == 2 ? 4.0f : 3.3f);
}

void advance(CrashVoiceRuntime& voice, float color, float ratio,
             double sampleRate) noexcept {
    const float baseHz = (235.0f + color * 115.0f) * ratio;
    for (int i = 0; i < kCrashModeCount; ++i) {
        const float slowChaos = 1.0f + 0.0035f * std::sin(
            static_cast<float>(voice.elapsedSec) * (2.1f + i * 0.37f) + i);
        const float hz = std::min(baseHz * kModeRatio[i] * slowChaos,
                                  static_cast<float>(sampleRate) * 0.43f);
        voice.modalPhase[i] += kTwoPi * hz / static_cast<float>(sampleRate);
        if (voice.modalPhase[i] >= kTwoPi) voice.modalPhase[i] -= kTwoPi;
        voice.modalSample[i] = std::sin(voice.modalPhase[i]);
    }
    voice.strikeSample = noise(voice.strikeNoiseState);
}

float render(CrashVoiceRuntime& voice, const CrashGeneratorParams& params,
             double sampleRate, float velocityGain, bool right) noexcept {
    const float color = std::clamp(params.crashColor, 0.0f, 1.0f);
    const float spread = std::clamp(params.crashSpread, 0.0f, 1.0f);
    const float totalDecay = decaySeconds(std::clamp(params.crashDecay, 0.0f, 1.0f),
                                          crashModelIndex(params.crashModel));
    if (!right) advance(
        voice, color,
        percussionPitchRatio(params.crashPitch, voice.pitch, 49,
                              params.crashKeyTrack),
        sampleRate);
    const double t = voice.elapsedSec;
    if (std::exp(-t / totalDecay) < 0.00001) { voice.active = 0; return 0.0f; }

    const float lowEnv = static_cast<float>(std::exp(-t / (totalDecay * 1.10f)));
    const float midEnv = static_cast<float>(std::exp(-t / (totalDecay * 0.82f)));
    const float highEnv = static_cast<float>(std::exp(
        -t / (totalDecay * (0.48f + color * 0.24f))));
    float low = 0.0f, mid = 0.0f, high = 0.0f;
    for (int i = 0; i < kCrashModeCount; ++i) {
        const float stereoWeight = right
            ? (1.0f + spread * 0.82f * kStereoShape[i])
            : (1.0f - spread * 0.82f * kStereoShape[i]);
        const float amp = stereoWeight / std::sqrt(1.0f + i * 0.72f);
        if (i < 4) low += voice.modalSample[i] * amp * lowEnv;
        else if (i < 10) mid += voice.modalSample[i] * amp * midEnv;
        else high += voice.modalSample[i] * amp * highEnv;
    }
    const float attack = static_cast<float>(std::exp(-t / 0.018));
    const float bloom = 1.0f - static_cast<float>(std::exp(-t / 0.035));
    float out = low * (0.10f + (1.0f - color) * 0.06f) +
                mid * (0.105f + color * 0.035f) * bloom +
                high * (0.075f + color * 0.075f) * bloom +
                voice.strikeSample * attack * 0.16f;
    out = std::tanh(out * 1.4f) * 0.78f;
    return out * velocityGain * params.gain * kInstrumentOutputGain;
}

} // namespace

int crashModelIndex(float model) noexcept {
    return std::clamp(static_cast<int>(std::lround(model * 2.0f)), 0, 2);
}

float crashGeneratorSampleL(CrashVoiceRuntime& voice, const CrashGeneratorParams& params,
                            double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    return render(voice, params, sampleRate, velocityGain, false);
}

float crashGeneratorSampleR(CrashVoiceRuntime& voice, const CrashGeneratorParams& params,
                            double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    return render(voice, params, sampleRate, velocityGain, true);
}

void triggerCrashVoice(CrashVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1; voice.pitch = pitch; voice.velocity = velocity;
    voice.strikeNoiseState = 0x5A17C9E3u ^ static_cast<uint32_t>(pitch) * 0x9E3779B9u;
    for (int i = 0; i < kCrashModeCount; ++i)
        voice.modalPhase[i] = 0.19f * i + 0.013f * static_cast<float>(pitch);
}

} // namespace audioapp
