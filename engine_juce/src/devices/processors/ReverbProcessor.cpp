#include "audioapp/devices/processors/ReverbProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {
constexpr float kPi = 3.14159265358979323846f;
constexpr float kInvSqrt8 = 0.3535533905932738f;

constexpr float kModeDelayMs[4][8] = {
    {19, 23, 29, 31, 37, 41, 43, 47},
    {27, 31, 37, 41, 43, 47, 53, 59},
    {43, 53, 61, 71, 79, 89, 97, 107},
    {67, 79, 89, 101, 113, 127, 139, 157},
};
constexpr float kModeDensity[4] = {.68f, 1.0f, .84f, .92f};
constexpr float kModeModRate[4] = {.34f, .22f, .12f, .07f};
constexpr float kModeModDepthMs[4] = {.16f, .12f, .28f, .72f};
constexpr float kModeOutput[4] = {.92f, 1.12f, 1.0f, .9f};

float lerp(float a, float b, float amount) noexcept {
    return a + (b - a) * amount;
}

void modeBlend(float morph, int& lower, int& upper, float& amount) noexcept {
    const float clamped = std::clamp(morph, 0.0f, 3.0f);
    lower = std::clamp(static_cast<int>(std::floor(clamped)), 0, 3);
    upper = std::min(lower + 1, 3);
    amount = clamped - static_cast<float>(lower);
}

void hadamard8(float* values) noexcept {
    for (int stride = 1; stride < 8; stride *= 2) {
        for (int base = 0; base < 8; base += stride * 2) {
            for (int offset = 0; offset < stride; ++offset) {
                const float a = values[base + offset];
                const float b = values[base + offset + stride];
                values[base + offset] = a + b;
                values[base + offset + stride] = a - b;
            }
        }
    }
    for (int i = 0; i < 8; ++i) values[i] *= kInvSqrt8;
}
}

bool ReverbProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bufferLeft_ != nullptr) return true;
    auto [left, right] = ctx.scratch.ringBufferArena.allocate();
    if (left == nullptr || right == nullptr) return false;
    bufferLeft_ = left;
    bufferRight_ = right;
    std::memset(bufferLeft_, 0,
                DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0,
                DeviceChainScratchArena::kBufferSize * sizeof(float));
    return true;
}

float* ReverbProcessor::lineBuffer(int line) noexcept {
    if (line < 4)
        return bufferLeft_ + kPreDelayCapacity + line * kLineCapacity;
    return bufferRight_ + kPreDelayCapacity + (line - 4) * kLineCapacity;
}

float ReverbProcessor::readLine(int line, float delaySamples) noexcept {
    const float clamped = std::clamp(delaySamples, 1.0f,
                                     static_cast<float>(kLineCapacity - 2));
    float readPosition = static_cast<float>(lineWriteIndex_[line]) - clamped;
    while (readPosition < 0.0f) readPosition += static_cast<float>(kLineCapacity);
    const int indexA = static_cast<int>(readPosition) % kLineCapacity;
    const int indexB = (indexA + 1) % kLineCapacity;
    const float fraction = readPosition - std::floor(readPosition);
    const float* buffer = lineBuffer(line);
    return lerp(buffer[indexA], buffer[indexB], fraction);
}

void ReverbProcessor::resetPlaybackState() noexcept {
    preWriteIndex_ = 0;
    std::memset(lineWriteIndex_, 0, sizeof(lineWriteIndex_));
    std::memset(dampingState_, 0, sizeof(dampingState_));
    std::memset(modulationPhase_, 0, sizeof(modulationPhase_));
    wetLowpassL_ = wetLowpassR_ = 0.0f;
    wetHighpassInputL_ = wetHighpassInputR_ = 0.0f;
    wetHighpassOutputL_ = wetHighpassOutputR_ = 0.0f;
    duckEnvelope_ = tailPeak_ = 0.0f;
    if (bufferLeft_ != nullptr)
        std::memset(bufferLeft_, 0,
                    DeviceChainScratchArena::kBufferSize * sizeof(float));
    if (bufferRight_ != nullptr)
        std::memset(bufferRight_, 0,
                    DeviceChainScratchArena::kBufferSize * sizeof(float));
}

void ReverbProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!ensureBuffers(ctx) || ctx.modulatedParams == nullptr) return;
    const auto params = std::get<ReverbParamsPlayback>(*ctx.modulatedParams);
    const float sampleRate = static_cast<float>(std::max(8000.0, ctx.sampleRate));
    const float inputGain = std::clamp(params.inputGain, 0.0f, 1.0f);
    const float decaySeconds = .15f * std::pow(100.0f, std::clamp(params.decay, 0.0f, 1.0f));
    const int preDelaySamples = std::clamp(
        static_cast<int>(std::round(std::clamp(params.preDelay, 0.0f, 1.0f) * .25f * sampleRate)),
        0, kPreDelayCapacity - 1);
    const float sizeScale = .55f + std::clamp(params.size, 0.0f, 1.0f) * 1.05f;
    const float dampingHz = 1200.0f * std::pow(15.0f, std::clamp(params.damping, 0.0f, 1.0f));
    const float dampingCoefficient = 1.0f - std::exp(-2.0f * kPi * dampingHz / sampleRate);
    const float lowCutHz = 20.0f * std::pow(50.0f, std::clamp(params.lowCut, 0.0f, 1.0f));
    const float highCutHz = 2000.0f * std::pow(10.0f, std::clamp(params.highCut, 0.0f, 1.0f));
    const float highpassCoefficient = std::exp(-2.0f * kPi * lowCutHz / sampleRate);
    const float lowpassCoefficient = 1.0f - std::exp(-2.0f * kPi * highCutHz / sampleRate);
    const float duckAmount = std::clamp(params.ducking, 0.0f, 1.0f);
    const float freeze = std::clamp(params.freeze, 0.0f, 1.0f);
    const float diffusionControl = std::clamp(params.diffusion, 0.0f, 1.0f);
    const float modulationControl = std::clamp(params.modulation, 0.0f, 1.0f);

    int lowerMode = 0;
    int upperMode = 0;
    float modeAmount = 0.0f;
    modeBlend(params.modeMorph, lowerMode, upperMode, modeAmount);
    const float density = lerp(kModeDensity[lowerMode], kModeDensity[upperMode], modeAmount);
    const float diffusion = std::clamp(diffusionControl * (.6f + .4f * density), 0.0f, 1.0f);
    const float modRate = lerp(kModeModRate[lowerMode], kModeModRate[upperMode], modeAmount);
    const float modDepthMs = lerp(kModeModDepthMs[lowerMode], kModeModDepthMs[upperMode], modeAmount)
        * modulationControl;
    const float outputScale = lerp(kModeOutput[lowerMode], kModeOutput[upperMode], modeAmount);
    const float attack = 1.0f - std::exp(-1.0f / (.008f * sampleRate));
    const float release = 1.0f - std::exp(-1.0f / (.18f * sampleRate));

    float blockTailPeak = 0.0f;
    for (int frame = 0; frame < block.numSamples; ++frame) {
        const float dryL = block.channelL[frame] * inputGain;
        const float dryR = block.channelR[frame] * inputGain;
        const float inputPeak = std::max(std::abs(dryL), std::abs(dryR));
        duckEnvelope_ += (inputPeak - duckEnvelope_)
            * (inputPeak > duckEnvelope_ ? attack : release);

        float preL = dryL;
        float preR = dryR;
        if (preDelaySamples > 0) {
            int readIndex = preWriteIndex_ - preDelaySamples;
            if (readIndex < 0) readIndex += kPreDelayCapacity;
            preL = bufferLeft_[readIndex];
            preR = bufferRight_[readIndex];
        }
        bufferLeft_[preWriteIndex_] = dryL;
        bufferRight_[preWriteIndex_] = dryR;
        preWriteIndex_ = (preWriteIndex_ + 1) % kPreDelayCapacity;

        float delayed[8];
        float damped[8];
        float delaySamples[8];
        for (int line = 0; line < 8; ++line) {
            const float baseMs = lerp(kModeDelayMs[lowerMode][line],
                                      kModeDelayMs[upperMode][line], modeAmount);
            const float phaseOffset = static_cast<float>(line) * .78539816339f;
            const float modulationMs = std::sin(modulationPhase_[line] + phaseOffset) * modDepthMs;
            delaySamples[line] = (baseMs * sizeScale + modulationMs) * .001f * sampleRate;
            delayed[line] = readLine(line, delaySamples[line]);
            dampingState_[line] += dampingCoefficient * (delayed[line] - dampingState_[line]);
            damped[line] = dampingState_[line];
            modulationPhase_[line] += 2.0f * kPi * modRate / sampleRate
                * (1.0f + static_cast<float>(line) * .017f);
            if (modulationPhase_[line] >= 2.0f * kPi) modulationPhase_[line] -= 2.0f * kPi;
        }

        float mixed[8];
        std::copy(std::begin(damped), std::end(damped), mixed);
        hadamard8(mixed);
        float feedbackVector[8];
        float sourceEnergy = 0.0f;
        float feedbackEnergy = 0.0f;
        for (int line = 0; line < 8; ++line) {
            feedbackVector[line] = lerp(damped[line], mixed[line], diffusion);
            sourceEnergy += damped[line] * damped[line];
            feedbackEnergy += feedbackVector[line] * feedbackVector[line];
        }
        const float diffusionCompensation = feedbackEnergy > 1.0e-20f
            ? std::min(4.0f, std::sqrt(sourceEnergy / feedbackEnergy))
            : 1.0f;
        const float inputMid = (preL + preR) * .5f;
        const float inputSide = (preL - preR) * .5f;
        for (int line = 0; line < 8; ++line) {
            const float diffuseValue = feedbackVector[line] * diffusionCompensation;
            const float lineDelaySeconds = delaySamples[line] / sampleRate;
            // The orthogonal network distributes energy across eight lines;
            // -1.5 calibrates the summed stereo amplitude to the requested
            // -60 dB RT60 rather than applying -60 dB to every line twice.
            const float feedback = std::pow(10.0f, -1.5f * lineDelaySeconds / decaySeconds);
            const float injection = ((line & 1) == 0 ? inputMid : inputSide)
                * (((line / 2) & 1) == 0 ? .42f : -.42f) * (1.0f - freeze);
            const float frozenFeedback = lerp(feedback, .99998f, freeze);
            lineBuffer(line)[lineWriteIndex_[line]] = injection + diffuseValue * frozenFeedback;
            lineWriteIndex_[line] = (lineWriteIndex_[line] + 1) % kLineCapacity;
        }

        float wetL = (delayed[0] + delayed[2] - delayed[4] - delayed[6]) * .25f * outputScale;
        float wetR = (delayed[1] - delayed[3] + delayed[5] - delayed[7]) * .25f * outputScale;
        const float hpL = highpassCoefficient
            * (wetHighpassOutputL_ + wetL - wetHighpassInputL_);
        const float hpR = highpassCoefficient
            * (wetHighpassOutputR_ + wetR - wetHighpassInputR_);
        wetHighpassInputL_ = wetL;
        wetHighpassInputR_ = wetR;
        wetHighpassOutputL_ = hpL;
        wetHighpassOutputR_ = hpR;
        wetLowpassL_ += lowpassCoefficient * (hpL - wetLowpassL_);
        wetLowpassR_ += lowpassCoefficient * (hpR - wetLowpassR_);
        const float duckGain = std::pow(10.0f, -duckAmount * (1.0f - freeze) * 18.0f
            * std::clamp(duckEnvelope_, 0.0f, 1.0f) / 20.0f);
        block.channelL[frame] = wetLowpassL_ * duckGain;
        block.channelR[frame] = wetLowpassR_ * duckGain;
        blockTailPeak = std::max(blockTailPeak,
            std::max(std::abs(block.channelL[frame]), std::abs(block.channelR[frame])));
    }
    tailPeak_ = std::max(blockTailPeak, tailPeak_ * .995f);

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(blockTailPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
