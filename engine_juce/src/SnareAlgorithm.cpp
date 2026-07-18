#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/PercussionPitch.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {
constexpr float kTwoPi = 6.28318530718f;

float noise(uint32_t& state) noexcept {
    state ^= state << 13; state ^= state >> 17; state ^= state << 5;
    return static_cast<float>(state) * (1.0f / 2147483648.0f) - 1.0f;
}
float overallDecay(float norm) noexcept { return 0.16f + norm * 0.46f; }
} // namespace

int snareModelIndex(float model) noexcept {
    return std::clamp(static_cast<int>(std::lround(model * 2.0f)), 0, 2);
}

void configureSnareVoice(SnareVoiceRuntime& voice, const SnareGeneratorParams& params,
                         float sampleRate) noexcept {
    if (sampleRate <= 0.0f) return;
    const float body = std::clamp(params.snareBody, 0.0f, 1.0f);
    const float ring = std::clamp(params.snareRing, 0.0f, 1.0f);
    const float tune = std::clamp(params.snareTune, 0.0f, 1.0f);
    const float snares = std::clamp(params.snareSnares, 0.0f, 1.0f);
    const float ratio = percussionPitchRatio(
        tune, voice.pitch, 38, params.snareKeyTrack);
    const float fundamental = 197.5f * ratio;
    const auto safeHz = [sampleRate](float hz) {
        return std::clamp(hz, 20.0f, sampleRate * 0.42f);
    };
    voice.membraneHz[0] = safeHz(fundamental);
    voice.membraneHz[1] = safeHz(fundamental * (1.61f + body * 0.09f));
    voice.membraneHz[2] = safeHz(fundamental * (2.27f + ring * 0.16f));
    voice.membraneDecaySec[0] = 0.085f + body * 0.16f;
    voice.membraneDecaySec[1] = 0.055f + body * 0.10f;
    voice.membraneDecaySec[2] = 0.035f + ring * 0.16f;
    voice.wiresDecaySec = 0.11f + snares * 0.34f;

    const float wireCenter = std::clamp(3400.0f * ratio,
                                        350.0f, sampleRate * 0.42f);
    cookSamplerBiquad(voice.wiresCoeffs, 2, sampleRate, wireCenter,
                      0.55f + (1.0f - snares) * 0.75f);
    cookSamplerBiquad(voice.ringCoeffs, 2, sampleRate,
                      std::min(wireCenter * 1.72f, sampleRate * 0.42f), 0.72f);
    cookSamplerBiquad(voice.snapCoeffs, 1, sampleRate,
                      2800.0f + params.snareSnap * 5200.0f, 0.707f);
}

float snareGeneratorSample(SnareVoiceRuntime& voice, const SnareGeneratorParams& params,
                           double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    if (voice.membraneHz[0] < 1.0f)
        configureSnareVoice(voice, params, static_cast<float>(sampleRate));
    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / overallDecay(params.snareDecay)));
    if (ampEnv < 0.00001f) { voice.active = 0; return 0.0f; }

    const float body = std::clamp(params.snareBody, 0.0f, 1.0f);
    const float ring = std::clamp(params.snareRing, 0.0f, 1.0f);
    float membrane = 0.0f;
    constexpr float modeAmp[3] = {0.62f, 0.27f, 0.16f};
    for (int i = 0; i < 3; ++i) {
        // Tiny strike bend, rather than the old octave-like pitch dive.
        const float bend = 1.0f + (0.025f + body * 0.035f) *
            static_cast<float>(std::exp(-t / 0.010));
        voice.membranePhase[i] += kTwoPi * voice.membraneHz[i] * bend /
                                  static_cast<float>(sampleRate);
        if (voice.membranePhase[i] >= kTwoPi) voice.membranePhase[i] -= kTwoPi;
        const float env = static_cast<float>(std::exp(-t / voice.membraneDecaySec[i]));
        membrane += std::sin(voice.membranePhase[i]) * env * modeAmp[i];
    }

    const float raw = noise(voice.noiseState);
    const float wire1 = processBiquadSample(raw, voice.wiresCoeffs, voice.wiresState);
    const float wire2 = processBiquadSample(raw, voice.ringCoeffs, voice.ringState);
    const float wireEnv = static_cast<float>(std::exp(-t / voice.wiresDecaySec));
    // Fast, irregular collisions make the wires chatter instead of forming a smooth noise pad.
    const float chatter = 0.72f + 0.28f * std::abs(std::sin(
        static_cast<float>(t) * (680.0f + params.snareSnares * 760.0f)));
    const float wires = (wire1 * 0.72f + wire2 * 0.38f) * wireEnv * chatter *
                        (0.16f + params.snareSnares * 0.56f);
    float snap = 0.0f;
    if (t < 0.018) {
        snap = processBiquadSample(raw, voice.snapCoeffs, voice.snapState) *
               static_cast<float>(std::exp(-t / 0.0028)) * params.snareSnap * 0.62f;
    }
    float mixed = membrane * (0.22f + body * 0.34f) +
                  membrane * wire1 * ring * 0.16f + wires + snap;
    // Mild asymmetric circuit-style compression removes sterile peaks.
    mixed = std::tanh(mixed * 1.45f + 0.08f) - std::tanh(0.08f);
    return mixed * ampEnv * velocityGain * params.gain * kInstrumentOutputGain * 0.82f;
}

void triggerSnareVoice(SnareVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1; voice.pitch = pitch; voice.velocity = velocity;
    voice.noiseState = 0x9E3779B9u ^ static_cast<uint32_t>(pitch) * 0x85EBCA6Bu;
    voice.membranePhase[1] = 0.13f; voice.membranePhase[2] = 0.31f;
}

} // namespace audioapp
