#include "audioapp/devices/processors/DistortionProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>

namespace audioapp {

void DistortionProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<DistortionParamsPlayback>(*ctx.modulatedParams);

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float drive = std::clamp(p.drive, 0.0f, 1.0f) * 8.0f + 0.5f; // 0.5..8.5
    float tone = std::clamp(p.tone, 0.0f, 1.0f);
    float mix = std::clamp(p.mix, 0.0f, 1.0f);
    float lpCoeff = std::clamp(tone * tone * 0.98f + 0.01f, 0.01f, 0.99f);

    for (int f = 0; f < block.numSamples; ++f) {
        float dryL = block.channelL[f];
        float dryR = block.channelR[f];

        // Tanh waveshaping
        float wetL = std::tanh(dryL * drive);
        float wetR = std::tanh(dryR * drive);

        // Simple one-pole low-pass for tone control
        lpStateL_ = lpStateL_ + lpCoeff * (wetL - lpStateL_);
        lpStateR_ = lpStateR_ + lpCoeff * (wetR - lpStateR_);
        wetL = lpStateL_;
        wetR = lpStateR_;

        block.channelL[f] = dryL * (1.0f - mix) + wetL * mix;
        block.channelR[f] = dryR * (1.0f - mix) + wetR * mix;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp