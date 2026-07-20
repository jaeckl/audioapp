#include "audioapp/devices/processors/DuckerProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/effects/DuckerParams.hpp"

#include <algorithm>
#include <cstring>

namespace audioapp {

void DuckerProcessor::rebuildSidechainFx(const DuckerParams& params) noexcept {
    sidechainFx_ = params.sidechainFx;
    arena_.reset();
    schedule_ = {};
    executionOrder_ = {};
    if (sidechainFx_ == nullptr || sidechainFx_->deviceCount <= 0) {
        return;
    }
    DeviceNodePlayback root;
    root.kind = kind();
    root.deviceId = deviceId();
    root.params = params;
    schedule_ = compileDeviceSubgraphTree(buildDeviceSubgraphTree(root));
    executionOrder_ = compileFusedChildExecutionOrder(
        schedule_,
        std::span<const DeviceNodePlayback>(sidechainFx_->devices,
                                            static_cast<size_t>(sidechainFx_->deviceCount)));
    if (!schedule_.valid() || !executionOrder_.valid()) {
        return;
    }
    try {
        arena_ = std::make_unique<ProcessorArena>(sidechainFx_->deviceCount);
        buildProcessorChain(sidechainFx_->devices, sidechainFx_->deviceCount, *arena_);
    } catch (...) {
        arena_.reset();
    }
}

void DuckerProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    if (const auto* p = std::get_if<DuckerParams>(&params)) {
        rebuildSidechainFx(*p);
    }
}

void DuckerProcessor::resetPlaybackState() noexcept {
    runtime_ = {};
    if (arena_) {
        resetPlaybackStateInArena(*arena_);
    }
}

bool DuckerProcessor::updateNestedDevice(const DeviceNodePlayback& node,
                                         bool paramsChanged) noexcept {
    if (!sidechainFx_ || !arena_) {
        return false;
    }
    for (int child = 0; child < sidechainFx_->deviceCount; ++child) {
        auto* processor = arena_->get(child);
        if (sidechainFx_->devices[child].deviceId == node.deviceId) {
            if (processor == nullptr) {
                return false;
            }
            if (paramsChanged) {
                processor->applyPlaybackNode(node);
            } else {
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

void DuckerProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<DuckerParams>(*ctx.modulatedParams);
    if (p.sidechainFx.get() != sidechainFx_.get()) {
        rebuildSidechainFx(p);
    }

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);

    const float* keyL = ctx.sidechainL;
    const float* keyR = ctx.sidechainR;
    const int n = block.numSamples;
    if (keyL != nullptr && keyR != nullptr && n > 0 && n <= kScratchFrames) {
        std::memcpy(keyL_, keyL, static_cast<size_t>(n) * sizeof(float));
        std::memcpy(keyR_, keyR, static_cast<size_t>(n) * sizeof(float));
        applyStereoScalarGain(keyL_, keyR_, n, std::clamp(p.sidechainGain, 0.0f, 1.0f));

        if (arena_ && sidechainFx_ && sidechainFx_->deviceCount > 0 &&
            schedule_.valid() && executionOrder_.valid()) {
            DeviceChainOrchestrator::Context sub(*arena_, ctx.scratch);
            sub.trackLeft = keyL_;
            sub.trackRight = keyR_;
            sub.numFrames = n;
            sub.sampleRate = ctx.sampleRate;
            sub.bpm = ctx.bpm;
            sub.playheadStartBeat = ctx.playheadBeat;
            sub.notes = ctx.notes;
            sub.noteCount = ctx.noteCount;
            sub.wavetableBank = ctx.wavetableBank;
            sub.lfoValues = ctx.lfoValues;
            sub.lfoCount = ctx.lfoCount;
            sub.modulators = ctx.modulators;
            sub.retriggerGeneration = ctx.retriggerGeneration;
            sub.tapGraph = ctx.tapGraph;
            sub.graphTapRuntimes = ctx.graphTapRuntimes;
            sub.graphTapRuntimeCount = ctx.graphTapRuntimeCount;
            sub.compiledDeviceOrder = executionOrder_.deviceIndices.data();
            sub.compiledDeviceOrderCount = executionOrder_.count;
            sub.automationClips = ctx.automationClips;
            sub.automationClipCount = ctx.automationClipCount;
            sub.modEdges = ctx.modEdges;
            sub.modEdgeCount = ctx.modEdgeCount;
            sub.deviceMeters = ctx.deviceMeters;
            sub.maxDeviceMeters = ctx.maxDeviceMeters;
            sub.meterSlotSubscribed = ctx.meterSlotSubscribed;
            DeviceChainScratchGuard scratchGuard(ctx.scratch, n);
            DeviceChainOrchestrator::processChain(sub);
        }
        keyL = keyL_;
        keyR = keyR_;
    }

    processDuckerStereoBlock(block.channelL, block.channelR, n, keyL, keyR, ctx.sampleRate, p,
                             runtime_);

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        ctx.deviceMeters[meterSlot].gainReductionDb.store(runtime_.gainReductionDb,
                                                          std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
