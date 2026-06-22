#include "audioapp/devices/processors/ChorusProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <cmath>

namespace audioapp {

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

void ChorusProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<ChorusParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float depth = std::clamp(p.depth, 0.0f, 1.0f);
    float rateHz = std::clamp(p.rateHz, 0.1f, 5.0f);
    float mix = std::clamp(p.mix, 0.0f, 1.0f);
    float centreDelayMs = std::clamp(p.centreDelayMs, 1.0f, 20.0f);
    float fb = std::clamp(p.feedback, 0.0f, 0.95f);

    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        lfoPhase_ += static_cast<float>((2.0 * 3.1415926535f * rateHz) / ctx.sampleRate);
        if (lfoPhase_ > static_cast<float>(2.0 * 3.1415926535f)) {
            lfoPhase_ -= static_cast<float>(2.0 * 3.1415926535f);
        }

        float delayMsL = centreDelayMs + depth * 5.0f * sinf(lfoPhase_);
        float delayMsR = centreDelayMs + depth * 5.0f * cosf(lfoPhase_);

        float delaySamplesL = (delayMsL / 1000.0f) * static_cast<float>(ctx.sampleRate);
        float delaySamplesR = (delayMsR / 1000.0f) * static_cast<float>(ctx.sampleRate);

        delaySamplesL = std::clamp(delaySamplesL, 1.0f,
                                   static_cast<float>(DeviceChainScratchArena::kBufferSize - 2));
        delaySamplesR = std::clamp(delaySamplesR, 1.0f,
                                   static_cast<float>(DeviceChainScratchArena::kBufferSize - 2));

        auto readInterpolated = [&](float* buf, float delayS) {
            int idx1 = (writeIndex_ - static_cast<int>(delayS) + DeviceChainScratchArena::kBufferSize)
                % DeviceChainScratchArena::kBufferSize;
            int idx2 = (idx1 - 1 + DeviceChainScratchArena::kBufferSize) % DeviceChainScratchArena::kBufferSize;
            float frac = delayS - floorf(delayS);
            return (1.0f - frac) * buf[idx1] + frac * buf[idx2];
        };

        float delayedL = readInterpolated(bufferLeft_, delaySamplesL);
        float delayedR = readInterpolated(bufferRight_, delaySamplesR);

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