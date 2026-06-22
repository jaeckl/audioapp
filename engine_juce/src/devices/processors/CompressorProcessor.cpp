#include "audioapp/devices/processors/CompressorProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"

namespace audioapp {

void CompressorProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<CompressorParams>(*ctx.modulatedParams);
    auto& runtime = runtime_;

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples, std::clamp(p.inputGain, 0.0f, 1.0f));
    const float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);

    processCompressorStereoBlock(block.channelL, block.channelR, block.numSamples, ctx.sampleRate, p, runtime);

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        ctx.deviceMeters[meterSlot].gainReductionDb.store(runtime.gainReductionDb, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp