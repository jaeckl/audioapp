#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/devices/processors/TrackGainProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

void TrackGainProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    const auto& common = ctx.commonControls;
    if (common.gainMode == CommonControlMode::Constant &&
        common.panMode == CommonControlMode::Constant) {
        const float pan = std::clamp(common.panEnd, 0.0f, 1.0f);
        const float leftBalance = pan <= 0.5f ? 1.0f : 2.0f * (1.0f - pan);
        const float rightBalance = pan >= 0.5f ? 1.0f : 2.0f * pan;
        multiplyScalarGain(
            block.channelL, block.numSamples, common.gainEnd * leftBalance);
        multiplyScalarGain(
            block.channelR, block.numSamples, common.gainEnd * rightBalance);
    } else {
        for (int f = 0; f < block.numSamples; ++f) {
            const float pan = std::clamp(common.panAt(f), 0.0f, 1.0f);
            const float leftBalance = pan <= 0.5f ? 1.0f : 2.0f * (1.0f - pan);
            const float rightBalance = pan >= 0.5f ? 1.0f : 2.0f * pan;
            const float gain = common.gainAt(f);
            block.channelL[f] *= gain * leftBalance;
            block.channelR[f] *= gain * rightBalance;
        }
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
