#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/devices/processors/FilterProcessor.hpp"

namespace audioapp {

void FilterProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<FilterParams>(*ctx.modulatedParams);
    processFilterStereoBlock(block.channelL, block.channelR, block.numSamples,
                             ctx.sampleRate, p, runtime_);
}

} // namespace audioapp