#include "audioapp/devices/processors/DeCracklerProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>
#include <algorithm>

namespace audioapp {

void DeCracklerProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {

    auto p = std::get<DeCracklerParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float sense = 0.02f + std::clamp(p.sensitivity, 0.0f, 1.0f) * 0.35f;
    const float strength = std::clamp(p.strength, 0.0f, 1.0f);
    const int width = 2 + static_cast<int>(std::clamp(p.width, 0.0f, 1.0f) * 30.0f);
    for (int i = 0; i < block.numSamples; ++i) {
        float l = block.channelL[i];
        float r = block.channelR[i];
        if (repairLeft_ > 0) {
            const float t = 1.0f - static_cast<float>(repairLeft_) / static_cast<float>(width);
            const float il = repairStartL_ + (repairEndL_ - repairStartL_) * t;
            const float ir = repairStartR_ + (repairEndR_ - repairStartR_) * t;
            l = l + (il - l) * strength;
            r = r + (ir - r) * strength;
            --repairLeft_;
        } else {
            const float dL = std::abs(l - prevL_);
            const float dR = std::abs(r - prevR_);
            if (dL > sense || dR > sense) {
                repairLeft_ = width;
                repairStartL_ = prevL_;
                repairStartR_ = prevR_;
                const int look = std::min(width, block.numSamples - i - 1);
                repairEndL_ = block.channelL[i + look];
                repairEndR_ = block.channelR[i + look];
            }
        }
        prevL_ = block.channelL[i];
        prevR_ = block.channelR[i];
        block.channelL[i] = l;
        block.channelR[i] = r;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
