#include "audioapp/devices/processors/ChainProcessor.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include <algorithm>
#include <cstring>

namespace audioapp {
void ChainProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    playback_ = std::get<ChainParams>(params).playback;
    try {
        arena_ = std::make_unique<ProcessorArena>(
            playback_ ? playback_->deviceCount : 1);
        if (playback_) buildProcessorChain(playback_->devices, playback_->deviceCount, *arena_);
    } catch (...) { arena_.reset(); }
}

void ChainProcessor::resetPlaybackState() noexcept {
    if (arena_) resetPlaybackStateInArena(*arena_);
}

void ChainProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!playback_ || !arena_ || block.numSamples > kScratchFrames) return;
    std::memcpy(dryL_, block.channelL, block.numSamples * sizeof(float));
    std::memcpy(dryR_, block.channelR, block.numSamples * sizeof(float));

    DeviceChainOrchestrator::Context sub(*arena_, ctx.scratch);
    sub.trackLeft=block.channelL; sub.trackRight=block.channelR; sub.numFrames=block.numSamples;
    sub.sampleRate=ctx.sampleRate; sub.bpm=ctx.bpm; sub.playheadStartBeat=ctx.playheadBeat;
    sub.notes=ctx.notes; sub.noteCount=ctx.noteCount; sub.wavetableBank=ctx.wavetableBank;
    sub.lfoValues=ctx.lfoValues; sub.lfoCount=ctx.lfoCount; sub.modulators=ctx.modulators;
    sub.retriggerGeneration=ctx.retriggerGeneration;

    AutomationClipPlayback automation[16]{}; int automationCount=0;
    if (ctx.automationClips) for(int a=0;a<ctx.automationClipCount&&automationCount<16;++a)
        for(int child=0;child<playback_->deviceCount;++child)
            if(ctx.automationClips[a].deviceIndex==playback_->devices[child].automationTargetIndex){
                automation[automationCount]=ctx.automationClips[a];
                automation[automationCount++].deviceIndex=static_cast<uint16_t>(child); break;
            }
    sub.automationClips=automationCount?automation:nullptr; sub.automationClipCount=automationCount;

    ModulationEdgePlayback edges[16]{}; int edgeCount=0;
    if (ctx.modEdges) for(int e=0;e<ctx.modEdgeCount&&edgeCount<16;++e)
        for(int child=0;child<playback_->deviceCount;++child)
            if(ctx.modEdges[e].deviceIndex==playback_->devices[child].automationTargetIndex){
                edges[edgeCount]=ctx.modEdges[e];
                edges[edgeCount++].deviceIndex=static_cast<uint16_t>(child); break;
            }
    sub.modEdges=edgeCount?edges:nullptr; sub.modEdgeCount=edgeCount;
    DeviceChainOrchestrator::processChain(sub);

    const auto* runtime = ctx.modulatedParams ? std::get_if<ChainParams>(ctx.modulatedParams) : nullptr;
    const auto& params = runtime ? *runtime : std::get<ChainParams>(storedParams());
    const float mix=std::clamp(params.mix,0.f,1.f), gain=std::clamp(params.gain,0.f,2.f);
    for(int i=0;i<block.numSamples;++i){
        block.channelL[i]=(dryL_[i]*(1-mix)+block.channelL[i]*mix)*gain;
        block.channelR[i]=(dryR_[i]*(1-mix)+block.channelR[i]*mix)*gain;
    }
}
}
