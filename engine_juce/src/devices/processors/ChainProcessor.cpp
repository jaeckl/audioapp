#include "audioapp/devices/processors/ChainProcessor.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include <algorithm>
#include <cstring>

namespace audioapp {
void ChainProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    playback_ = std::get<ChainParams>(params).playback;
    DeviceNodePlayback root;
    root.kind = kind();
    root.deviceId = deviceId();
    root.params = params;
    schedule_ = compileDeviceSubgraphTree(buildDeviceSubgraphTree(root));
    executionOrder_ = playback_ == nullptr
        ? CompiledDeviceExecutionOrder{}
        : compileFusedChildExecutionOrder(
            schedule_,
            std::span<const DeviceNodePlayback>(playback_->devices,
                                                 static_cast<size_t>(playback_->deviceCount)));
    if (!schedule_.valid() || !executionOrder_.valid()) {
        arena_.reset();
        return;
    }
    try {
        arena_ = std::make_unique<ProcessorArena>(
            playback_ ? playback_->deviceCount : 1);
        if (playback_) buildProcessorChain(playback_->devices, playback_->deviceCount, *arena_);
    } catch (...) { arena_.reset(); }
}

bool ChainProcessor::updateNestedDevice(const DeviceNodePlayback& node,
                                        bool paramsChanged) noexcept {
    if (!playback_ || !arena_) return false;
    for (int child = 0; child < playback_->deviceCount; ++child) {
        auto* processor = arena_->get(child);
        if (playback_->devices[child].deviceId == node.deviceId) {
            if (processor == nullptr) return false;
            if (paramsChanged) processor->applyPlaybackNode(node);
            else {
                processor->bypassed = node.bypassed;
                processor->gain = node.gain;
                processor->pan = node.pan;
                processor->outputMix = node.outputMix;
                processor->outputWidth = node.outputWidth;
            }
            return true;
        }
        if (processor != nullptr && processor->updateNestedDevice(node, paramsChanged)) {
            return true;
        }
    }
    return false;
}

bool ChainProcessor::setNestedCompiledParameter(uint64_t processorNodeId,
                                                 uint16_t parameterId,
                                                 float value,
                                                 ParameterUpdateRate rate,
                                                 float startValue) noexcept {
    if (!arena_) return false;
    for (int child = 0; playback_ && child < playback_->deviceCount; ++child) {
        auto* processor = arena_->get(child);
        if (processor == nullptr) continue;
        if (processor->stableProcessorNodeId == processorNodeId)
            return processor->setCompiledParameter(parameterId, value, rate, startValue);
        if (processor->setNestedCompiledParameter(
                processorNodeId, parameterId, value, rate, startValue))
            return true;
    }
    return false;
}

bool ChainProcessor::readNestedEffectiveParameter(uint64_t processorNodeId,
                                                   uint16_t parameterId,
                                                   float& value,
                                                   float* automationBase) const noexcept {
    if (!arena_ || !playback_) return false;
    for (int child = 0; child < playback_->deviceCount; ++child) {
        const auto* processor = arena_->get(child);
        if (processor == nullptr) continue;
        if (processor->stableProcessorNodeId == processorNodeId)
            return processor->readEffectiveParameter(parameterId, value, automationBase);
        if (processor->readNestedEffectiveParameter(processorNodeId, parameterId,
                                                    value, automationBase))
            return true;
    }
    return false;
}

bool ChainProcessor::setNestedResolvedAsset(
    uint64_t processorNodeId, const ResolvedAssetUpdate& update) noexcept {
    if (!arena_ || !playback_) return false;
    for (int child = 0; child < playback_->deviceCount; ++child) {
        auto* processor = arena_->get(child);
        if (processor == nullptr) continue;
        if (processor->stableProcessorNodeId == processorNodeId)
            return processor->applyResolvedAsset(update);
        if (processor->setNestedResolvedAsset(processorNodeId, update)) return true;
    }
    return false;
}

void ChainProcessor::bindCompiledParameterSpans(
    const AutomationClipPlayback* clips, int clipCount,
    const ModulationEdgePlayback* edges, int edgeCount) noexcept {
    DeviceProcessor::bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    for (int child = 0; playback_ && arena_ && child < playback_->deviceCount; ++child)
        if (auto* processor = arena_->get(child))
            processor->bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
}

void ChainProcessor::resetPlaybackState() noexcept {
    if (arena_) resetPlaybackStateInArena(*arena_);
}

void ChainProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!playback_ || !arena_ || !schedule_.valid() || !executionOrder_.valid() ||
        block.numSamples > kScratchFrames) return;
    std::memcpy(dryL_, block.channelL, block.numSamples * sizeof(float));
    std::memcpy(dryR_, block.channelR, block.numSamples * sizeof(float));

    DeviceChainOrchestrator::Context sub(*arena_, ctx.scratch);
    sub.trackLeft=block.channelL; sub.trackRight=block.channelR; sub.numFrames=block.numSamples;
    sub.sampleRate=ctx.sampleRate; sub.bpm=ctx.bpm; sub.playheadStartBeat=ctx.playheadBeat;
    sub.notes=ctx.notes; sub.noteCount=ctx.noteCount; sub.wavetableBank=ctx.wavetableBank;
    sub.lfoValues=ctx.lfoValues; sub.lfoCount=ctx.lfoCount; sub.modulators=ctx.modulators;
    sub.retriggerGeneration=ctx.retriggerGeneration;
    sub.tapGraph=ctx.tapGraph; sub.graphTapRuntimes=ctx.graphTapRuntimes;
    sub.graphTapRuntimeCount=ctx.graphTapRuntimeCount;
    sub.compiledDeviceOrder = executionOrder_.deviceIndices.data();
    sub.compiledDeviceOrderCount = executionOrder_.count;

    sub.automationClips = ctx.automationClips;
    sub.automationClipCount = ctx.automationClipCount;
    sub.modEdges = ctx.modEdges;
    sub.modEdgeCount = ctx.modEdgeCount;
    sub.deviceMeters = ctx.deviceMeters;
    sub.maxDeviceMeters = ctx.maxDeviceMeters;
    sub.meterSlotSubscribed = ctx.meterSlotSubscribed;
    DeviceChainScratchGuard scratchGuard(ctx.scratch, block.numSamples);
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
