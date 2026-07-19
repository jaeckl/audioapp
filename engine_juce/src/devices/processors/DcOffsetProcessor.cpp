#include "audioapp/devices/processors/DcOffsetProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>
#include <algorithm>

namespace audioapp {

void DcOffsetProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {

    auto p = std::get<DcOffsetParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float amount = std::clamp(p.amount, 0.0f, 1.0f);
    const float cutoff = std::clamp(p.cutoff, 0.0f, 1.0f);
    const bool hpf = p.mode >= 0.5f;
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    if (hpf) {
        const float hz = 20.0f + cutoff * 180.0f;
        const float x = std::exp(-2.0f * 3.14159265f * hz / sr);
        for (int i = 0; i < block.numSamples; ++i) {
            const float inL = block.channelL[i];
            const float inR = block.channelR[i];
            stateA_ = x * (stateA_ + inL - prevL_);
            stateB_ = x * (stateB_ + inR - prevR_);
            prevL_ = inL;
            prevR_ = inR;
            block.channelL[i] = inL + (stateA_ - inL) * amount;
            block.channelR[i] = inR + (stateB_ - inR) * amount;
        }
    } else {
        const float a = 0.001f;
        for (int i = 0; i < block.numSamples; ++i) {
            const float mid = 0.5f * (block.channelL[i] + block.channelR[i]);
            stateC_ += a * (mid - stateC_);
            block.channelL[i] -= stateC_ * amount;
            block.channelR[i] -= stateC_ * amount;
        }
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
