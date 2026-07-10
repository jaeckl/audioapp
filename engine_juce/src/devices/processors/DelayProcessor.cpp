#include "audioapp/devices/processors/DelayProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <cmath>
#include <cstring>

namespace audioapp {

bool DelayProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bufferLeft_ != nullptr) return true;
    auto [bufL, bufR] = ctx.scratch.ringBufferArena.allocate();
    if (bufL == nullptr) return false;
    bufferLeft_ = bufL;
    bufferRight_ = bufR;
    std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    return true;
}

float DelayProcessor::processAllPass(float input, int channel, int stage,
                                     int delaySamples, float coefficient) noexcept {
    delaySamples = std::clamp(delaySamples, 1, kDiffusionBufferSize - 1);
    int& index = diffusionIndices_[channel][stage];
    if (index >= delaySamples) index = 0;
    float& delayed = diffusion_[channel][stage][index];
    const float output = delayed - coefficient * input;
    delayed = input + coefficient * output;
    if (++index >= delaySamples) index = 0;
    return output;
}

void DelayProcessor::resetPlaybackState() noexcept {
    writeIndex_ = 0;
    lfoPhase_ = 0.0f;
    tailPeak_ = 0.0f;
    std::memset(diffusion_, 0, sizeof(diffusion_));
    std::memset(diffusionIndices_, 0, sizeof(diffusionIndices_));
    std::memset(lowPassState_, 0, sizeof(lowPassState_));
    std::memset(highPassState_, 0, sizeof(highPassState_));
    std::memset(highPassInput_, 0, sizeof(highPassInput_));
    duckEnvelope_ = 0.0f;
    if (bufferLeft_ != nullptr) {
        std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    }
    if (bufferRight_ != nullptr) {
        std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    }
}

void DelayProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<DelayParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float delayTimeMs = std::clamp(p.timeMs, 0.0f, 5000.0f);
    const int timeMode = std::clamp(static_cast<int>(std::round(p.timeMode)), 0, 3);
    if (timeMode > 0) {
        const float beatsPerNote = timeMode == 1 ? 0.25f : timeMode == 2 ? 0.5f : 1.0f;
        delayTimeMs = std::clamp(
            std::round(p.noteCount) * beatsPerNote * 60000.0f / static_cast<float>(std::max(ctx.bpm, 1)),
            0.0f, 5000.0f);
    }
    int delaySamples = static_cast<int>(std::round((delayTimeMs / 1000.0f) * ctx.sampleRate));
    delaySamples = std::clamp(delaySamples, 1, DeviceChainScratchArena::kBufferSize - 1);

    float fb = std::clamp(p.feedback, 0.0f, 0.95f);
    float mix = std::clamp(p.mix, 0.0f, 1.0f);
    const int blurMode = std::clamp(static_cast<int>(std::round(p.blurMode)), 0, 2);
    const float blurAmount = std::clamp(p.blurAmount, 0.0f, 1.0f);
    const float duckAmount = std::clamp(p.inputDucking, 0.0f, 1.0f);
    const float lowCut = std::clamp(p.lowCutHz, 20.0f, 2000.0f);
    const float highCut = std::clamp(
        std::max(p.highCutHz, lowCut * 2.0f), 2000.0f, 20000.0f);
    constexpr float pi = 3.14159265358979323846f;
    const float hpCoefficient = 1.0f / (1.0f + 2.0f * pi * lowCut / static_cast<float>(ctx.sampleRate));
    const float lpCoefficient = 1.0f - std::exp(-2.0f * pi * highCut / static_cast<float>(ctx.sampleRate));
    const float duckAttack = std::exp(-1.0f / (0.008f * static_cast<float>(ctx.sampleRate)));
    const float duckRelease = std::exp(-1.0f / (0.180f * static_cast<float>(ctx.sampleRate)));
    const int diffusionStageCount = blurMode == 1 ? 2 : 4;
    const float diffusionCoefficient = blurMode == 1 ? 0.46f : 0.64f;
    // Mutually-prime-ish lengths avoid reinforcing a single pitch. Right-side
    // offsets decorrelate the channels without moving the dry signal.
    static constexpr float kDelayMs[2][kDiffusionStages] = {
        {3.1f, 5.3f, 8.9f, 13.1f},
        {3.7f, 5.9f, 9.7f, 14.3f},
    };

    float blockTailPeak = 0.0f;
    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        const float inputEnvelope = std::min(1.0f, std::max(std::abs(dryL), std::abs(dryR)));
        const float duckCoefficient = inputEnvelope > duckEnvelope_ ? duckAttack : duckRelease;
        duckEnvelope_ = duckCoefficient * duckEnvelope_ + (1.0f - duckCoefficient) * inputEnvelope;
        const float duckGain = 1.0f - duckAmount * duckEnvelope_;

        int readIdx = (writeIndex_ - delaySamples + DeviceChainScratchArena::kBufferSize)
            % DeviceChainScratchArena::kBufferSize;
        float delayedL = bufferLeft_[readIdx];
        float delayedR = bufferRight_[readIdx];

        const float hpL = hpCoefficient * (highPassState_[0] + delayedL - highPassInput_[0]);
        const float hpR = hpCoefficient * (highPassState_[1] + delayedR - highPassInput_[1]);
        highPassInput_[0] = delayedL;
        highPassInput_[1] = delayedR;
        highPassState_[0] = hpL;
        highPassState_[1] = hpR;
        lowPassState_[0] += lpCoefficient * (hpL - lowPassState_[0]);
        lowPassState_[1] += lpCoefficient * (hpR - lowPassState_[1]);
        delayedL = lowPassState_[0];
        delayedR = lowPassState_[1];
        if (blurMode > 0) {
            float diffusedL = delayedL;
            float diffusedR = delayedR;
            for (int stage = 0; stage < diffusionStageCount; ++stage) {
                const int delayL = static_cast<int>(ctx.sampleRate * kDelayMs[0][stage] / 1000.0);
                const int delayR = static_cast<int>(ctx.sampleRate * kDelayMs[1][stage] / 1000.0);
                diffusedL = processAllPass(diffusedL, 0, stage, delayL, diffusionCoefficient);
                diffusedR = processAllPass(diffusedR, 1, stage, delayR, diffusionCoefficient);
            }
            if (blurMode == 1) {
                const float blend = 0.65f * blurAmount;
                delayedL = (1.0f - blend) * delayedL + blend * diffusedL;
                delayedR = (1.0f - blend) * delayedR + blend * diffusedR;
            } else {
                // A gentle energy-preserving stereo rotation makes Wide Blur
                // broader after the denser four-stage diffusion network.
                const float rotatedL = 0.94f * diffusedL + 0.342f * diffusedR;
                const float rotatedR = 0.94f * diffusedR - 0.342f * diffusedL;
                const float blend = 0.9f * blurAmount;
                delayedL = (1.0f - blend) * delayedL + blend * rotatedL;
                delayedR = (1.0f - blend) * delayedR + blend * rotatedR;
            }
        }

        block.channelL[f] = (1.0f - mix) * dryL + mix * duckGain * delayedL;
        block.channelR[f] = (1.0f - mix) * dryR + mix * duckGain * delayedR;

        bufferLeft_[writeIndex_] = dryL + fb * delayedL;
        bufferRight_[writeIndex_] = dryR + fb * delayedR;
        blockTailPeak = std::max(blockTailPeak,
            std::max(std::abs(bufferLeft_[writeIndex_]), std::abs(bufferRight_[writeIndex_])));

        writeIndex_ = (writeIndex_ + 1) % DeviceChainScratchArena::kBufferSize;
    }
    tailPeak_ = blockTailPeak;

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
