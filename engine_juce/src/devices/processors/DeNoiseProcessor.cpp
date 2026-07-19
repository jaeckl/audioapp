#include "audioapp/devices/processors/DeNoiseProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>
#include <algorithm>

namespace audioapp {

void DeNoiseProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {

    auto p = std::get<DeNoiseParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float thresh = std::clamp(p.threshold, 0.0f, 1.0f) * 0.25f;
    const float reduce = std::clamp(p.reduction, 0.0f, 1.0f);
    const float smooth = 0.05f + std::clamp(p.smoothing, 0.0f, 1.0f) * 0.9f;
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    const float hp = std::exp(-2.0f * 3.14159265f * 3000.0f / sr);
    for (int i = 0; i < block.numSamples; ++i) {
        const float inL = block.channelL[i];
        const float inR = block.channelR[i];
        stateA_ = hp * (stateA_ + inL - prevL_);
        stateB_ = hp * (stateB_ + inR - prevR_);
        prevL_ = inL;
        prevR_ = inR;
        const float noise = 0.5f * (std::abs(stateA_) + std::abs(stateB_));
        float target = 1.0f;
        if (noise < thresh)
            target = 1.0f - reduce * (1.0f - noise / std::max(thresh, 1.0e-6f));
        stateC_ = stateC_ * smooth + target * (1.0f - smooth);
        block.channelL[i] = inL * stateC_;
        block.channelR[i] = inR * stateC_;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
