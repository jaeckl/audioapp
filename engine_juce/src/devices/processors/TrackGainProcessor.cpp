#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/devices/processors/TrackGainProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

void TrackGainProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    for (int f = 0; f < block.numSamples; ++f) {
        const float pan=std::clamp(ctx.scratch.perFramePan[f],0.0f,1.0f);
        const float leftBalance=pan<=.5f?1.0f:2.0f*(1.0f-pan);
        const float rightBalance=pan>=.5f?1.0f:2.0f*pan;
        block.channelL[f] *= ctx.scratch.perFrameGain[f]*leftBalance;
        block.channelR[f] *= ctx.scratch.perFrameGain[f]*rightBalance;
    }
    if(isMeterSlotSubscribed(ctx,meterSlot)&&ctx.deviceMeters!=nullptr&&
       meterSlot>=0&&meterSlot<ctx.maxDeviceMeters){
        float peakL=0.0f,peakR=0.0f;
        for(int f=0;f<block.numSamples;++f){peakL=std::max(peakL,std::abs(block.channelL[f]));peakR=std::max(peakR,std::abs(block.channelR[f]));}
        auto& meter=ctx.deviceMeters[meterSlot];
        meter.inputPeakL.store(peakL,std::memory_order_relaxed);
        meter.inputPeakR.store(peakR,std::memory_order_relaxed);
        meter.inputPeak.store(std::max(peakL,peakR),std::memory_order_relaxed);
    }
}

} // namespace audioapp
