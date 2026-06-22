#include "audioapp/devices/processors/PhaserProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <cmath>

namespace audioapp {

bool PhaserProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bufferLeft_ != nullptr) return true;
    auto [bufL, bufR] = ctx.scratch.ringBufferArena.allocate();
    if (bufL == nullptr) return false;
    bufferLeft_ = bufL;
    bufferRight_ = bufR;
    std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    return true;
}

void PhaserProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<PhaserParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float depth = std::clamp(p.depth, 0.0f, 1.0f);
    float rateHz = std::clamp(p.rateHz, 0.1f, 5.0f);
    float fb = std::clamp(p.feedback, 0.0f, 0.95f);
    float centreFreq = std::clamp(p.centreFrequencyHz, 20.0f, 20000.0f);

    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        lfoPhase_ += static_cast<float>((2.0 * 3.1415926535f * rateHz) / ctx.sampleRate);
        if (lfoPhase_ > static_cast<float>(2.0 * 3.1415926535f)) {
            lfoPhase_ -= static_cast<float>(2.0 * 3.1415926535f);
        }

        float modFreq = centreFreq * powf(2.0f, depth * 2.0f * sinf(lfoPhase_));
        modFreq = std::clamp(modFreq, 20.0f, static_cast<float>(ctx.sampleRate * 0.49));

        float g = -cosf(3.1415926535f * modFreq / static_cast<float>(ctx.sampleRate));

        float inL = dryL + fb * phaserStateL_[3];
        float inR = dryR + fb * phaserStateR_[3];

        for (int i = 0; i < 4; ++i) {
            float xL = inL;
            float yL = g * xL + phaserStateL_[i];
            phaserStateL_[i] = xL - g * yL;
            inL = yL;

            float xR = inR;
            float yR = g * xR + phaserStateR_[i];
            phaserStateR_[i] = xR - g * yR;
            inR = yR;
        }

        block.channelL[f] = 0.5f * (dryL + inL);
        block.channelR[f] = 0.5f * (dryR + inR);
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp