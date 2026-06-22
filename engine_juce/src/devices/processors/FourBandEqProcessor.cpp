#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/devices/processors/FourBandEqProcessor.hpp"

namespace audioapp {

void FourBandEqProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<FourBandEqParams>(*ctx.modulatedParams);
    processFourBandEqStereoBlock(block.channelL, block.channelR, block.numSamples,
                                 ctx.sampleRate, p, runtime_);
}

} // namespace audioapp