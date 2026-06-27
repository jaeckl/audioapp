#include "audioapp/devices/processors/BitcrusherProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>

namespace audioapp {

void BitcrusherProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<BitcrusherParamsPlayback>(*ctx.modulatedParams);

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    // Map rate 0-1 to sample-rate decimation factor (1 = full, near-0 = heavy)
    float holdFrames = 1.0f + (1.0f - std::clamp(p.rate, 0.0f, 1.0f)) * 63.0f;
    float bits = std::clamp(p.bits, 1.0f, 16.0f);
    float quantLevels = std::pow(2.0f, bits);
    float mix = std::clamp(p.mix, 0.0f, 1.0f);

    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        // Sample-rate decimation (hold)
        phase_ += 1.0f;
        if (phase_ >= holdFrames) {
            phase_ -= holdFrames;
        }

        float outL, outR;
        if (phase_ < 1.0f) {
            // Quantize to bit depth
            outL = std::round(dryL * quantLevels) / quantLevels;
            outR = std::round(dryR * quantLevels) / quantLevels;
            heldL_ = outL;
            heldR_ = outR;
        } else {
            outL = heldL_;
            outR = heldR_;
        }

        block.channelL[f] = dryL * (1.0f - mix) + outL * mix;
        block.channelR[f] = dryR * (1.0f - mix) + outR * mix;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp