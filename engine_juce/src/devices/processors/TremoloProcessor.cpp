#include "audioapp/devices/processors/TremoloProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>

namespace audioapp {

void TremoloProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<TremoloParamsPlayback>(*ctx.modulatedParams);

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    float depth = std::clamp(p.depth, 0.0f, 1.0f);
    float rateHz = std::clamp(p.rateHz, 0.1f, 20.0f);
    float shape = std::clamp(p.shape, 0.0f, 1.0f);

    for (int f = 0; f < block.numSamples; ++f) {
        lfoPhase_ += static_cast<float>((2.0 * 3.1415926535 * rateHz) / ctx.sampleRate);
        if (lfoPhase_ > static_cast<float>(2.0 * 3.1415926535)) {
            lfoPhase_ -= static_cast<float>(2.0 * 3.1415926535);
        }

        // Sine LFO
        float sineLfo = 0.5f + 0.5f * std::sin(lfoPhase_);
        // Square LFO (shape 0 = sine, 1 = square, linear blend)
        float squareLfo = (lfoPhase_ < static_cast<float>(3.1415926535)) ? 1.0f : 0.0f;
        float lfo = sineLfo * (1.0f - shape) + squareLfo * shape;

        float gain = 1.0f - depth + depth * lfo;

        block.channelL[f] *= gain;
        block.channelR[f] *= gain;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp