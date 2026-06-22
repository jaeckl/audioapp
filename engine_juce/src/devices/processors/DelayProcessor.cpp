#include "audioapp/devices/processors/DelayProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <cmath>

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

void DelayProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<DelayParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float delayTimeMs = std::clamp(p.timeMs, 1.0f, 2000.0f);
    int delaySamples = static_cast<int>(std::round((delayTimeMs / 1000.0f) * ctx.sampleRate));
    delaySamples = std::clamp(delaySamples, 1, DeviceChainScratchArena::kBufferSize - 1);

    float fb = std::clamp(p.feedback, 0.0f, 0.95f);
    float mix = std::clamp(p.mix, 0.0f, 1.0f);

    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        int readIdx = (writeIndex_ - delaySamples + DeviceChainScratchArena::kBufferSize)
            % DeviceChainScratchArena::kBufferSize;
        float delayedL = bufferLeft_[readIdx];
        float delayedR = bufferRight_[readIdx];

        block.channelL[f] = (1.0f - mix) * dryL + mix * delayedL;
        block.channelR[f] = (1.0f - mix) * dryR + mix * delayedR;

        bufferLeft_[writeIndex_] = dryL + fb * delayedL;
        bufferRight_[writeIndex_] = dryR + fb * delayedR;

        writeIndex_ = (writeIndex_ + 1) % DeviceChainScratchArena::kBufferSize;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp