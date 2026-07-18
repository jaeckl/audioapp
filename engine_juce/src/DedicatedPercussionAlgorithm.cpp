#include "audioapp/DedicatedPercussionAlgorithm.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/PercussionPitch.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {

constexpr float kTwoPi = 6.28318530718f;
constexpr float kHatHz[6] = {205.3f, 304.4f, 369.6f, 522.7f, 540.2f, 800.0f};
constexpr float kRideHz[6] = {276.4f, 418.1f, 603.7f, 824.6f, 1137.2f, 1571.9f};

float pulse(float phase) noexcept { return phase < 3.14159265f ? 1.0f : -1.0f; }

float noise(MetallicPercussionVoiceRuntime& voice) noexcept {
    voice.noiseState = std::fmod(voice.noiseState * 3.9876543f + 0.1234567f, 1.0f);
    return voice.noiseState * 2.0f - 1.0f;
}

void trigger(MetallicPercussionVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseState = 0.173f + static_cast<float>(pitch) * 0.0071f;
    voice.configuredA = -1.0f;
}

float pitchRatio(float pitch, int midiPitch, int anchor, float keyTrack) noexcept {
    return percussionPitchRatio(pitch, midiPitch, anchor, keyTrack);
}

void generateMetal(MetallicPercussionVoiceRuntime& voice, const float* frequencies,
                   float ratio, float spread, double sampleRate) noexcept {
    float s[6];
    for (int i = 0; i < 6; ++i) {
        voice.phase[i] += kTwoPi * frequencies[i] * ratio / static_cast<float>(sampleRate);
        if (voice.phase[i] >= kTwoPi) voice.phase[i] -= kTwoPi;
        s[i] = pulse(voice.phase[i]);
    }
    const float a = s[0] * s[1];
    const float b = s[2] * s[5];
    const float c = s[3] * s[4];
    voice.sampleL = a * 0.38f + b * 0.34f + c * 0.28f;
    voice.sampleR = voice.sampleL * (1.0f - spread * 0.32f) +
                    (a * 0.44f - b * 0.31f + c * 0.25f) * spread;
}

void configure(MetallicPercussionVoiceRuntime& voice, float value, float ratio,
               float bodyHz, float colorHz, float sampleRate) noexcept {
    if (voice.configuredA == value && voice.configuredRatio == ratio &&
        voice.configuredSampleRate == sampleRate) return;
    const auto hz = [sampleRate, ratio](float v) {
        return std::clamp(v * ratio, 35.0f, sampleRate * 0.43f);
    };
    cookSamplerBiquad(voice.bodyCoeffs, 2, sampleRate, hz(bodyHz), 0.72f);
    cookSamplerBiquad(voice.colorCoeffs, 2, sampleRate, hz(colorHz), 0.62f);
    voice.configuredA = value;
    voice.configuredRatio = ratio;
    voice.configuredSampleRate = sampleRate;
}

float renderHihat(HihatVoiceRuntime& voice, const HihatGeneratorParams& p,
                  double sampleRate, float velocityGain, bool right) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float ratio = pitchRatio(p.hihatPitch, voice.pitch, 42, p.hihatKeyTrack);
    const float color = std::clamp(p.hihatColor, 0.0f, 1.0f);
    configure(voice, color, ratio, 1800.0f + color * 2200.0f,
              6200.0f + color * 5000.0f, static_cast<float>(sampleRate));
    if (!right) generateMetal(voice, kHatHz, ratio * (0.92f + color * 0.16f), p.hihatWidth, sampleRate);
    const float decay = hihatReleaseSeconds(p);
    const float tight = std::clamp(p.hihatTightness, 0.0f, 1.0f);
    const float env = std::exp(static_cast<float>(-voice.elapsedSec) / decay);
    const float tick = std::exp(static_cast<float>(-voice.elapsedSec) / (0.0015f + (1.0f - tight) * 0.006f));
    if (env < 0.00001f) { voice.active = 0; return 0.0f; }
    const float src = (right ? voice.sampleR : voice.sampleL) * (1.0f - p.hihatNoise * 0.35f) +
                      noise(voice) * p.hihatNoise;
    auto& bs = right ? voice.bodyR : voice.bodyL;
    auto& cs = right ? voice.colorR : voice.colorL;
    const float body = processBiquadSample(src, voice.bodyCoeffs, bs);
    const float air = processBiquadSample(src, voice.colorCoeffs, cs);
    const float out = (body * 0.38f + air * (0.38f + color * 0.34f)) * env + src * tick * 0.18f;
    return std::tanh(out * 1.35f) * 0.62f * velocityGain * p.gain * kInstrumentOutputGain;
}

float renderRide(RideVoiceRuntime& voice, const RideGeneratorParams& p,
                 double sampleRate, float velocityGain, bool right) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float ratio = pitchRatio(p.ridePitch, voice.pitch, 51, p.rideKeyTrack);
    const float bright = std::clamp(p.rideBrightness, 0.0f, 1.0f);
    configure(voice, bright, ratio, 1100.0f + bright * 1700.0f,
              4800.0f + bright * 6200.0f, static_cast<float>(sampleRate));
    if (!right) generateMetal(voice, kRideHz, ratio, p.rideWidth, sampleRate);
    const float decay = rideReleaseSeconds(p);
    const float damping = std::clamp(p.rideDamping, 0.0f, 1.0f);
    const float env = std::exp(static_cast<float>(-voice.elapsedSec) / decay);
    const float shimmer = std::exp(static_cast<float>(-voice.elapsedSec) /
                                   (decay * (0.48f + (1.0f - damping) * 0.44f)));
    if (env < 0.00001f) { voice.active = 0; return 0.0f; }
    const float src = right ? voice.sampleR : voice.sampleL;
    auto& bs = right ? voice.bodyR : voice.bodyL;
    auto& cs = right ? voice.colorR : voice.colorL;
    const float bow = processBiquadSample(src, voice.bodyCoeffs, bs);
    const float wash = processBiquadSample(src, voice.colorCoeffs, cs);
    const float bellHz = 1450.0f * ratio;
    const float bell = std::sin(kTwoPi * bellHz * static_cast<float>(voice.elapsedSec)) *
                       std::exp(static_cast<float>(-voice.elapsedSec) / (decay * 0.68f));
    const float out = bow * env * (0.46f - bright * 0.24f) +
                      wash * shimmer * (0.04f + bright * 0.90f) +
                      bell * p.rideBell * 0.44f;
    return std::tanh(out * 1.2f) * 0.58f * velocityGain * p.gain * kInstrumentOutputGain;
}

float renderTom(TomVoiceRuntime& voice, const TomGeneratorParams& p,
                double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float ratio = pitchRatio(p.tomPitch, voice.pitch, 45, p.tomKeyTrack);
    const float decay = tomReleaseSeconds(p);
    const float t = static_cast<float>(voice.elapsedSec);
    const float env = std::exp(-t / decay);
    if (env < 0.00001f) { voice.active = 0; return 0.0f; }
    const float baseHz = 52.0f * ratio;
    const float bend = 1.0f + p.tomBend * 2.8f * std::exp(-t / 0.035f);
    voice.phase[0] += kTwoPi * baseHz * bend / static_cast<float>(sampleRate);
    voice.phase[1] += kTwoPi * baseHz * 1.47f / static_cast<float>(sampleRate);
    const float fundamental = std::sin(voice.phase[0]);
    const float overtone = std::sin(voice.phase[1]) * (1.0f - p.tomBody) * 0.42f;
    const float click = noise(voice) * p.tomNoise * std::exp(-t / (0.004f + p.tomAttack * 0.014f));
    const float out = (fundamental * (0.52f + p.tomBody * 0.38f) + overtone) * env + click;
    return std::tanh(out * (1.1f + p.tomAttack * 0.9f)) * 0.72f * velocityGain * p.gain * kInstrumentOutputGain;
}

float renderRimshot(RimshotVoiceRuntime& voice, const RimshotGeneratorParams& p,
                    double sampleRate, float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) return 0.0f;
    const float ratio = pitchRatio(p.rimshotPitch, voice.pitch, 37, p.rimshotKeyTrack);
    const float decay = rimshotReleaseSeconds(p);
    const float t = static_cast<float>(voice.elapsedSec);
    const float env = std::exp(-t / decay);
    if (env < 0.00001f) { voice.active = 0; return 0.0f; }
    const float hz = (610.0f + p.rimshotTone * 980.0f) * ratio;
    voice.phase[0] += kTwoPi * hz / static_cast<float>(sampleRate);
    voice.phase[1] += kTwoPi * hz * 1.73f / static_cast<float>(sampleRate);
    const float wood = std::sin(voice.phase[0]) * 0.62f + std::sin(voice.phase[1]) * 0.28f;
    const float snap = noise(voice) * p.rimshotSnap * std::exp(-t / 0.0035f);
    const float body = std::sin(voice.phase[0] * 0.49f) * p.rimshotBody * std::exp(-t / (decay * 1.35f));
    const float out = wood * env + snap + body * 0.32f;
    return std::tanh(out * 1.8f) * 0.58f * velocityGain * p.gain * kInstrumentOutputGain;
}

} // namespace

void triggerHihatVoice(HihatVoiceRuntime& v, int p, float vel) noexcept { trigger(v, p, vel); }
void triggerRideVoice(RideVoiceRuntime& v, int p, float vel) noexcept { trigger(v, p, vel); }
void triggerTomVoice(TomVoiceRuntime& v, int p, float vel) noexcept { trigger(v, p, vel); }
void triggerRimshotVoice(RimshotVoiceRuntime& v, int p, float vel) noexcept { trigger(v, p, vel); }

float hihatSampleL(HihatVoiceRuntime& v, const HihatGeneratorParams& p, double sr, float vel) noexcept { return renderHihat(v, p, sr, vel, false); }
float hihatSampleR(HihatVoiceRuntime& v, const HihatGeneratorParams& p, double sr, float vel) noexcept { return renderHihat(v, p, sr, vel, true); }
float rideSampleL(RideVoiceRuntime& v, const RideGeneratorParams& p, double sr, float vel) noexcept { return renderRide(v, p, sr, vel, false); }
float rideSampleR(RideVoiceRuntime& v, const RideGeneratorParams& p, double sr, float vel) noexcept { return renderRide(v, p, sr, vel, true); }
float tomSampleL(TomVoiceRuntime& v, const TomGeneratorParams& p, double sr, float vel) noexcept {
    v.sampleL = renderTom(v, p, sr, vel);
    return v.sampleL;
}
float tomSampleR(TomVoiceRuntime& v, const TomGeneratorParams&, double, float) noexcept {
    return v.sampleL;
}
float rimshotSampleL(RimshotVoiceRuntime& v, const RimshotGeneratorParams& p, double sr, float vel) noexcept {
    v.sampleL = renderRimshot(v, p, sr, vel);
    return v.sampleL;
}
float rimshotSampleR(RimshotVoiceRuntime& v, const RimshotGeneratorParams&, double, float) noexcept {
    return v.sampleL;
}

float hihatReleaseSeconds(const HihatGeneratorParams& p) noexcept { return 0.035f + p.hihatDecay * 0.62f; }
float rideReleaseSeconds(const RideGeneratorParams& p) noexcept { return 0.42f + p.rideDecay * 3.8f; }
float tomReleaseSeconds(const TomGeneratorParams& p) noexcept { return 0.10f + p.tomDecay * 1.25f; }
float rimshotReleaseSeconds(const RimshotGeneratorParams& p) noexcept { return 0.025f + p.rimshotDecay * 0.32f; }

} // namespace audioapp
