#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/devices/processors/TrackGainProcessor.hpp"

namespace audioapp {

void TrackGainProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    for (int f = 0; f < block.numSamples; ++f) {
        block.channelL[f] *= ctx.scratch.perFrameGain[f];
        block.channelR[f] *= ctx.scratch.perFrameGain[f];
    }
}

} // namespace audioapp