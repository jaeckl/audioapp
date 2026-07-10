#include "audioapp/devices/processors/ChorusProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {
constexpr float kPi = 3.14159265358979323846f;
constexpr float kTwoPi = 2.0f * kPi;

struct ChorusConfig {
    float rateHz = 1.0f;
    float depthMs = 3.0f;
    float delayMs = 8.0f;
    float feedback = 0.0f;
    float voices = 1.0f;
    float spread = 0.5f;
    float wander = 0.0f;
    float shape = 0.0f;
    float lowCutHz = 20.0f;
    float highCutHz = 20000.0f;
};

float lerp(float a, float b, float t) noexcept { return a + (b - a) * t; }

ChorusConfig configForMode(int mode, const float* p) noexcept {
    ChorusConfig c;
    switch (mode) {
    case 1: // Ensemble: Rate, Depth, Voices, Spread, Drift, Tone
        c.rateHz = 0.05f + p[0] * 1.95f;
        c.depthMs = 0.5f + p[1] * 8.0f;
        c.delayMs = 9.0f + p[1] * 7.0f;
        c.feedback = 0.08f;
        c.voices = 2.0f + p[2] * 2.0f;
        c.spread = p[3];
        c.wander = p[4] * 0.45f;
        c.highCutHz = 3000.0f + p[5] * 17000.0f;
        break;
    case 2: // Dimension: Amount, Delay, Spread, Motion, Low Cut, High Cut
        c.rateHz = 0.04f + p[3] * 0.75f;
        c.depthMs = 0.1f + p[0] * 2.8f;
        c.delayMs = 4.0f + p[1] * 20.0f;
        c.feedback = 0.0f;
        c.voices = 4.0f;
        c.spread = p[2];
        c.lowCutHz = 20.0f * std::pow(50.0f, p[4]);
        c.highCutHz = 2000.0f * std::pow(10.0f, p[5]);
        break;
    case 3: // Drift: Speed, Depth, Wander, Delay, Stereo, Tone
        c.rateHz = 0.02f + p[0] * 0.98f;
        c.depthMs = 0.5f + p[1] * 10.0f;
        c.delayMs = 3.0f + p[3] * 27.0f;
        c.feedback = 0.12f;
        c.voices = 2.0f;
        c.spread = p[4];
        c.wander = p[2];
        c.highCutHz = 2500.0f + p[5] * 17500.0f;
        break;
    default: // Classic: Rate, Depth, Delay, Feedback, Phase, Shape
        c.rateHz = 0.1f + p[0] * 4.9f;
        c.depthMs = 0.2f + p[1] * 7.8f;
        c.delayMs = 2.0f + p[2] * 18.0f;
        c.feedback = p[3] * 0.8f;
        c.voices = 1.0f;
        c.spread = p[4];
        c.shape = p[5];
        break;
    }
    return c;
}

ChorusConfig interpolate(const ChorusConfig& a, const ChorusConfig& b, float t) noexcept {
    ChorusConfig c;
    c.rateHz = lerp(a.rateHz, b.rateHz, t);
    c.depthMs = lerp(a.depthMs, b.depthMs, t);
    c.delayMs = lerp(a.delayMs, b.delayMs, t);
    c.feedback = lerp(a.feedback, b.feedback, t);
    c.voices = lerp(a.voices, b.voices, t);
    c.spread = lerp(a.spread, b.spread, t);
    c.wander = lerp(a.wander, b.wander, t);
    c.shape = lerp(a.shape, b.shape, t);
    c.lowCutHz = lerp(a.lowCutHz, b.lowCutHz, t);
    c.highCutHz = lerp(a.highCutHz, b.highCutHz, t);
    return c;
}
}

bool ChorusProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bufferLeft_ != nullptr) return true;
    auto [bufL, bufR] = ctx.scratch.ringBufferArena.allocate();
    if (bufL == nullptr) return false;
    bufferLeft_ = bufL;
    bufferRight_ = bufR;
    std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    return true;
}

void ChorusProcessor::resetPlaybackState() noexcept {
    writeIndex_ = 0;
    lfoPhase_ = 0.0f;
    wanderState_ = wanderTarget_ = 0.0f;
    wanderCounter_ = 0;
    lowPassState_[0] = lowPassState_[1] = 0.0f;
    highPassState_[0] = highPassState_[1] = 0.0f;
    highPassInput_[0] = highPassInput_[1] = 0.0f;
    if (bufferLeft_) std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    if (bufferRight_) std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
}

void ChorusProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    const auto p = std::get<ChorusParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    const float morph = std::clamp(p.modeMorph, 0.0f, 3.0f);
    const int lowerMode = std::min(static_cast<int>(std::floor(morph)), 2);
    const int upperMode = std::min(lowerMode + 1, 3);
    const float morphFraction = morph - static_cast<float>(lowerMode);
    const ChorusConfig config = interpolate(
        configForMode(lowerMode, p.modeParams[lowerMode]),
        configForMode(upperMode, p.modeParams[upperMode]), morphFraction);

    const float hpCoefficient = 1.0f / (1.0f + kTwoPi * config.lowCutHz / static_cast<float>(ctx.sampleRate));
    const float lpCoefficient = 1.0f - std::exp(-kTwoPi * config.highCutHz / static_cast<float>(ctx.sampleRate));

    auto readInterpolated = [&](float* buffer, float delaySamples) noexcept {
        delaySamples = std::clamp(delaySamples, 1.0f,
                                  static_cast<float>(DeviceChainScratchArena::kBufferSize - 2));
        const int whole = static_cast<int>(delaySamples);
        const int first = (writeIndex_ - whole + DeviceChainScratchArena::kBufferSize)
            % DeviceChainScratchArena::kBufferSize;
        const int second = (first - 1 + DeviceChainScratchArena::kBufferSize)
            % DeviceChainScratchArena::kBufferSize;
        const float fraction = delaySamples - static_cast<float>(whole);
        return lerp(buffer[first], buffer[second], fraction);
    };

    for (int frame = 0; frame < block.numSamples; ++frame) {
        const float dryL = block.channelL[frame];
        const float dryR = block.channelR[frame];
        lfoPhase_ += kTwoPi * config.rateHz / static_cast<float>(ctx.sampleRate);
        if (lfoPhase_ >= kTwoPi) lfoPhase_ -= kTwoPi;

        if (--wanderCounter_ <= 0) {
            rngState_ ^= rngState_ << 13;
            rngState_ ^= rngState_ >> 17;
            rngState_ ^= rngState_ << 5;
            wanderTarget_ = static_cast<float>(rngState_ & 0xFFFFu) / 32767.5f - 1.0f;
            wanderCounter_ = 1024;
        }
        wanderState_ += (wanderTarget_ - wanderState_) * 0.0007f;

        float wetL = 0.0f, wetR = 0.0f, weightSum = 0.0f;
        for (int voice = 0; voice < kMaxVoices; ++voice) {
            const float weight = std::clamp(config.voices - static_cast<float>(voice), 0.0f, 1.0f);
            if (weight <= 0.0f) continue;
            const float voicePhase = static_cast<float>(voice) * kTwoPi / static_cast<float>(kMaxVoices);
            const float leftPhase = lfoPhase_ + voicePhase * config.spread;
            const float rightPhase = leftPhase + kPi * config.spread;
            const auto shapedL = lerp(std::sin(leftPhase), 2.0f / kPi * std::asin(std::sin(leftPhase)), config.shape);
            const auto shapedR = lerp(std::sin(rightPhase), 2.0f / kPi * std::asin(std::sin(rightPhase)), config.shape);
            const float wander = wanderState_ * config.wander * (voice % 2 == 0 ? 1.0f : -1.0f);
            const float delayL = config.delayMs + config.depthMs * (shapedL + wander);
            const float delayR = config.delayMs + config.depthMs * (shapedR - wander);
            wetL += weight * readInterpolated(bufferLeft_, delayL * static_cast<float>(ctx.sampleRate) / 1000.0f);
            wetR += weight * readInterpolated(bufferRight_, delayR * static_cast<float>(ctx.sampleRate) / 1000.0f);
            weightSum += weight;
        }
        wetL /= std::max(weightSum, 1.0f);
        wetR /= std::max(weightSum, 1.0f);

        const float hpL = hpCoefficient * (highPassState_[0] + wetL - highPassInput_[0]);
        const float hpR = hpCoefficient * (highPassState_[1] + wetR - highPassInput_[1]);
        highPassInput_[0] = wetL; highPassInput_[1] = wetR;
        highPassState_[0] = hpL; highPassState_[1] = hpR;
        lowPassState_[0] += lpCoefficient * (hpL - lowPassState_[0]);
        lowPassState_[1] += lpCoefficient * (hpR - lowPassState_[1]);
        wetL = lowPassState_[0]; wetR = lowPassState_[1];

        block.channelL[frame] = wetL;
        block.channelR[frame] = wetR;
        bufferLeft_[writeIndex_] = dryL + config.feedback * wetL;
        bufferRight_[writeIndex_] = dryR + config.feedback * wetR;
        writeIndex_ = (writeIndex_ + 1) % DeviceChainScratchArena::kBufferSize;
    }

    if (ctx.deviceMeters && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        const float peak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(peak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
