#include "audioapp/devices/processors/DistortionProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>

namespace audioapp {

namespace {

float waveshapeSample(float x, float driveGain, float bias) noexcept {
    // Asymmetric tanh: bias shifts the operating point, then DC is removed.
    const float wet = std::tanh((x + bias) * driveGain);
    const float dc = std::tanh(bias * driveGain);
    return wet - dc;
}

} // namespace

void DistortionProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<DistortionParamsPlayback>(*ctx.modulatedParams);

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    const float driveGain = std::clamp(p.drive, 0.0f, 1.0f) * 8.0f + 0.5f; // 0.5..8.5
    const float tone = std::clamp(p.tone, 0.0f, 1.0f);
    const float mix = std::clamp(p.mix, 0.0f, 1.0f);
    const float bias = (std::clamp(p.sym, 0.0f, 1.0f) - 0.5f) * 1.2f; // ~-0.6..0.6
    const float lpCoeff = std::clamp(tone * tone * 0.98f + 0.01f, 0.01f, 0.99f);

    for (int f = 0; f < block.numSamples; ++f) {
        const float dryL = block.channelL[f];
        const float dryR = block.channelR[f];

        float wetL = waveshapeSample(dryL, driveGain, bias);
        float wetR = waveshapeSample(dryR, driveGain, bias);

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
