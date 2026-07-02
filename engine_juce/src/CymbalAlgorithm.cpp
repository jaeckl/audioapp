#include "audioapp/CymbalAlgorithm.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {

constexpr float kTwoPi = 6.28318530718f;
constexpr float kOscHz[6] = {205.3f, 304.4f, 369.6f, 522.7f, 540.2f, 800.0f};

float decaySeconds(float decay, int model) noexcept {
    if (model == 1) return 0.18f + decay * 1.25f;
    if (model == 2) return 0.07f + decay * 0.42f;
    return 0.045f + decay * 0.72f;
}

float pulse(float phase) noexcept { return phase < 3.14159265f ? 1.0f : -1.0f; }

void configure(CymbalVoiceRuntime& voice, float color, float sampleRate) noexcept {
    if (voice.configuredColor == color && voice.configuredSampleRate == sampleRate) return;
    cookSamplerBiquad(voice.bodyCoeffs, 2, sampleRate, 1150.0f + color * 1750.0f, 0.72f);
    cookSamplerBiquad(voice.sizzleCoeffs, 2, sampleRate, 4300.0f + color * 5200.0f, 0.62f);
    cookSamplerBiquad(voice.highpassCoeffs, 1, sampleRate, 520.0f + color * 1150.0f, 0.707f);
    voice.configuredColor = color;
    voice.configuredSampleRate = sampleRate;
}

void generateMetal(CymbalVoiceRuntime& voice, float color, float width, double sampleRate) noexcept {
    float s[6];
    const float tune = 0.88f + color * 0.30f;
    for (int i = 0; i < 6; ++i) {
        voice.oscillatorPhase[i] += kTwoPi * kOscHz[i] * tune / static_cast<float>(sampleRate);
        if (voice.oscillatorPhase[i] >= kTwoPi) voice.oscillatorPhase[i] -= kTwoPi;
        s[i] = pulse(voice.oscillatorPhase[i]);
    }
    // Pairwise multiplication supplies stable sum/difference sidebands; unequal sums avoid pitch.
    const float a = s[0] * s[1];
    const float b = s[2] * s[5];
    const float c = s[3] * s[4];
    const float cluster = (a * 0.34f + b * 0.31f + c * 0.27f +
                           (s[0] + s[2] - s[4]) * 0.08f);
    voice.metallicSampleL = cluster;
    voice.metallicSampleR = cluster * (1.0f - width * 0.22f) +
                            (a * 0.22f - b * 0.34f + c * 0.44f) * width;
}

float render(CymbalVoiceRuntime& voice, const CymbalGeneratorParams& params,
             double sampleRate, float velocityGain, bool right) noexcept {
    const float color = std::clamp(params.cymbalColor, 0.0f, 1.0f);
    const float width = std::clamp(params.cymbalWidth, 0.0f, 1.0f);
    const int model = cymbalModelIndex(params.cymbalModel);
    configure(voice, color, static_cast<float>(sampleRate));
    if (!right) generateMetal(voice, color, width, sampleRate);

    const double t = voice.elapsedSec;
    const float tau = decaySeconds(std::clamp(params.cymbalDecay, 0.0f, 1.0f), model);
    const float bodyEnv = static_cast<float>(std::exp(-t / tau));
    if (bodyEnv < 0.00001f) { voice.active = 0; return 0.0f; }
    const float attackEnv = static_cast<float>(std::exp(-t / 0.010));
    const float shimmerEnv = static_cast<float>(std::exp(-t / (tau * 0.72f + 0.025f)));
    const float source = right ? voice.metallicSampleR : voice.metallicSampleL;
    auto& bodyState = right ? voice.bodyStateR : voice.bodyStateL;
    auto& sizzleState = right ? voice.sizzleStateR : voice.sizzleStateL;
    auto& hpState = right ? voice.highpassStateR : voice.highpassStateL;
    const float body = processBiquadSample(source, voice.bodyCoeffs, bodyState);
    const float sizzle = processBiquadSample(source, voice.sizzleCoeffs, sizzleState);
    const float air = processBiquadSample(source, voice.highpassCoeffs, hpState);
    float out = body * (0.48f - color * 0.12f) * bodyEnv +
                sizzle * (0.25f + color * 0.30f) * shimmerEnv +
                air * attackEnv * 0.13f;
    out = std::tanh(out * 1.35f) * 0.72f;
    return out * velocityGain * params.gain * kInstrumentOutputGain;
}

} // namespace

int cymbalModelIndex(float model) noexcept {
    return std::clamp(static_cast<int>(std::lround(model * 2.0f)), 0, 2);
}

float cymbalGeneratorSampleL(CymbalVoiceRuntime& voice, const CymbalGeneratorParams& params,
                             double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    return render(voice, params, sampleRate, velocityGain, false);
}

float cymbalGeneratorSampleR(CymbalVoiceRuntime& voice, const CymbalGeneratorParams& params,
                             double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    return render(voice, params, sampleRate, velocityGain, true);
}

void triggerCymbalVoice(CymbalVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.configuredColor = -1.0f;
}

} // namespace audioapp
