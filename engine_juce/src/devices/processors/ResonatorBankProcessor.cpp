#include "audioapp/devices/processors/ResonatorBankProcessor.hpp"

namespace audioapp {

void ResonatorBankProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    const auto params = std::get<ResonatorBankParams>(*ctx.modulatedParams);
    processResonatorBankStereoBlock(block.channelL, block.channelR, block.numSamples,
                                    ctx.sampleRate, params, runtime_);
}

} // namespace audioapp
