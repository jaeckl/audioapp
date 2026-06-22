#include "audioapp/devices/processors/ReverbProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <cmath>

namespace audioapp {

bool ReverbProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bufferLeft_ != nullptr) return true;
    auto [bufL, bufR] = ctx.scratch.ringBufferArena.allocate();
    if (bufL == nullptr) return false;
    bufferLeft_ = bufL;
    bufferRight_ = bufR;
    std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    return true;
}

void ReverbProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<ReverbParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float roomSize = std::clamp(p.roomSize, 0.0f, 1.0f);
    float wet = std::clamp(p.wetLevel, 0.0f, 1.0f);
    float dry = std::clamp(p.dryLevel, 0.0f, 1.0f);

    // Tap delay times in samples
    int tapsL[4] = { 1601, 2377, 3511, 4999 };
    int tapsR[4] = { 1867, 2693, 3821, 5413 };

    float sizeScale = 0.5f + 1.5f * roomSize;
    float fb = 0.7f + 0.25f * roomSize;

    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        float wetL = 0.0f;
        float wetR = 0.0f;

        for (int i = 0; i < 4; ++i) {
            int dL = static_cast<int>(tapsL[i] * sizeScale);
            dL = std::clamp(dL, 10, DeviceChainScratchArena::kBufferSize - 1);
            int readIdxL = (writeIndex_ - dL + DeviceChainScratchArena::kBufferSize)
                % DeviceChainScratchArena::kBufferSize;
            wetL += bufferLeft_[readIdxL];

            int dR = static_cast<int>(tapsR[i] * sizeScale);
            dR = std::clamp(dR, 10, DeviceChainScratchArena::kBufferSize - 1);
            int readIdxR = (writeIndex_ - dR + DeviceChainScratchArena::kBufferSize)
                % DeviceChainScratchArena::kBufferSize;
            wetR += bufferRight_[readIdxR];
        }

        wetL *= 0.25f;
        wetR *= 0.25f;

        // Simple 1st-order allpass diffusion stages on the wet signal
        float apG = 0.6f;
        float xApL = wetL;
        float yApL = apG * xApL + phaserStateL_[0];
        phaserStateL_[0] = xApL - apG * yApL;
        wetL = yApL;

        float xApR = wetR;
        float yApR = apG * xApR + phaserStateR_[0];
        phaserStateR_[0] = xApR - apG * yApR;
        wetR = yApR;

        block.channelL[f] = dry * dryL + wet * wetL;
        block.channelR[f] = dry * dryR + wet * wetR;

        bufferLeft_[writeIndex_] = dryL + fb * wetL;
        bufferRight_[writeIndex_] = dryR + fb * wetR;

        writeIndex_ = (writeIndex_ + 1) % DeviceChainScratchArena::kBufferSize;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp