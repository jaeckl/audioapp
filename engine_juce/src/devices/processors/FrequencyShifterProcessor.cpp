#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/devices/processors/FrequencyShifterProcessor.hpp"

namespace audioapp {

void FrequencyShifterProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<FrequencyShifterParams>(*ctx.modulatedParams);
    processFrequencyShifterStereoBlock(block.channelL, block.channelR, block.numSamples,
                                       ctx.sampleRate, p, runtime_);
}

} // namespace audioapp