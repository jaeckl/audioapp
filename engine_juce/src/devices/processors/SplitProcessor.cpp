#include "audioapp/devices/processors/SplitProcessor.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"

#include <algorithm>
#include <cstring>
#include <span>

namespace audioapp {

void SplitProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    branches_[0] = BranchRuntime{};
    branches_[1] = BranchRuntime{};
    playback_ = std::get<SplitParams>(params).playback;
    if (playback_ == nullptr) return;

    DeviceNodePlayback root;
    root.kind = kind();
    root.deviceId = deviceId();
    root.params = params;
    schedule_ = compileDeviceSubgraphTree(buildDeviceSubgraphTree(root));
    if (!schedule_.valid()) return;

    try {
        for (int b = 0; b < 2; ++b) {
            const auto& branch = playback_->branches[b];
            if (branch.deviceCount <= 0) continue;
            auto order = compileFusedChildExecutionOrder(
                schedule_,
                std::span<const DeviceNodePlayback>(
                    branch.devices, static_cast<size_t>(branch.deviceCount)));
            if (!order.valid()) continue;
            branches_[b].executionOrder = order;
            branches_[b].arena = std::make_unique<ProcessorArena>(branch.deviceCount);
            buildProcessorChain(branch.devices, branch.deviceCount, *branches_[b].arena);
        }
    } catch (...) {
        branches_[0] = BranchRuntime{};
        branches_[1] = BranchRuntime{};
    }
}

bool SplitProcessor::updateNestedDevice(const DeviceNodePlayback& node,
                                        bool paramsChanged) noexcept {
    if (playback_ == nullptr) return false;
    for (int b = 0; b < 2; ++b) {
        auto& runtime = branches_[b];
        if (!runtime.arena) continue;
        const auto& branch = playback_->branches[b];
        for (int child = 0; child < branch.deviceCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (branch.devices[child].deviceId == node.deviceId) {
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
    }
    return false;
}

bool SplitProcessor::setNestedCompiledParameter(uint64_t processorNodeId,
                                                uint16_t parameterId,
                                                float value,
                                                ParameterUpdateRate rate,
                                                float startValue) noexcept {
    for (int b = 0; b < 2; ++b) {
        auto& runtime = branches_[b];
        if (!runtime.arena) continue;
        const int childCount = playback_ ? playback_->branches[b].deviceCount : 0;
        for (int child = 0; child < childCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->setCompiledParameter(parameterId, value, rate, startValue);
            if (processor->setNestedCompiledParameter(
                    processorNodeId, parameterId, value, rate, startValue))
                return true;
        }
    }
    return false;
}

bool SplitProcessor::setNestedResolvedAsset(uint64_t processorNodeId,
                                            const ResolvedAssetUpdate& update) noexcept {
    for (int b = 0; b < 2; ++b) {
        auto& runtime = branches_[b];
        if (!runtime.arena) continue;
        const int childCount = playback_ ? playback_->branches[b].deviceCount : 0;
        for (int child = 0; child < childCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->applyResolvedAsset(update);
            if (processor->setNestedResolvedAsset(processorNodeId, update)) return true;
        }
    }
    return false;
}

bool SplitProcessor::readNestedEffectiveParameter(uint64_t processorNodeId,
                                                  uint16_t parameterId,
                                                  float& value,
                                                  float* automationBase) const noexcept {
    for (int b = 0; b < 2; ++b) {
        const auto& runtime = branches_[b];
        if (!runtime.arena) continue;
        const int childCount = playback_ ? playback_->branches[b].deviceCount : 0;
        for (int child = 0; child < childCount; ++child) {
            const auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->readEffectiveParameter(parameterId, value, automationBase);
            if (processor->readNestedEffectiveParameter(processorNodeId, parameterId,
                                                         value, automationBase))
                return true;
        }
    }
    return false;
}

void SplitProcessor::bindCompiledParameterSpans(
    const AutomationClipPlayback* clips, int clipCount,
    const ModulationEdgePlayback* edges, int edgeCount) noexcept {
    DeviceProcessor::bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    for (int b = 0; b < 2; ++b) {
        auto& runtime = branches_[b];
        if (!runtime.arena) continue;
        const int childCount = playback_ ? playback_->branches[b].deviceCount : 0;
        for (int child = 0; child < childCount; ++child)
            if (auto* processor = runtime.arena->get(child))
                processor->bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    }
}

void SplitProcessor::resetPlaybackState() noexcept {
    for (auto& runtime : branches_) {
        if (runtime.arena) resetPlaybackStateInArena(*runtime.arena);
    }
}

void SplitProcessor::runBranch(int branchIndex, float* left, float* right, int numSamples,
                               ProcessContext& ctx) noexcept {
    auto& runtime = branches_[branchIndex];
    if (!runtime.arena || !runtime.executionOrder.valid()) return;

    DeviceChainOrchestrator::Context sub(*runtime.arena, ctx.scratch);
    sub.trackLeft = left;
    sub.trackRight = right;
    sub.numFrames = numSamples;
    sub.sampleRate = ctx.sampleRate;
    sub.bpm = ctx.bpm;
    sub.playheadStartBeat = ctx.playheadBeat;
    sub.notes = ctx.notes;
    sub.noteCount = ctx.noteCount;
    sub.wavetableBank = ctx.wavetableBank;
    sub.suppressInstruments = ctx.suppressInstruments;
    sub.lfoValues = ctx.lfoValues;
    sub.lfoCount = ctx.lfoCount;
    sub.modulators = ctx.modulators;
    sub.retriggerGeneration = ctx.retriggerGeneration;
    sub.tapGraph = ctx.tapGraph;
    sub.graphTapRuntimes = ctx.graphTapRuntimes;
    sub.graphTapRuntimeCount = ctx.graphTapRuntimeCount;
    sub.compiledDeviceOrder = runtime.executionOrder.deviceIndices.data();
    sub.compiledDeviceOrderCount = runtime.executionOrder.count;
    sub.automationClips = ctx.automationClips;
    sub.automationClipCount = ctx.automationClipCount;
    sub.modEdges = ctx.modEdges;
    sub.modEdgeCount = ctx.modEdgeCount;
    sub.deviceMeters = ctx.deviceMeters;
    sub.maxDeviceMeters = ctx.maxDeviceMeters;
    sub.meterSlotSubscribed = ctx.meterSlotSubscribed;
    DeviceChainScratchGuard scratchGuard(ctx.scratch, numSamples);
    DeviceChainOrchestrator::processChain(sub);
}

void SplitProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (playback_ == nullptr || block.numSamples <= 0 ||
        block.numSamples > kScratchFrames) return;

    const size_t bytes = static_cast<size_t>(block.numSamples) * sizeof(float);
    const SplitMode mode = playback_->mode;

    // Encode: branch0 is written in place into the block (no dedicated
    // buffer needed); branch1 gets the two scratch buffers below.
    if (mode == SplitMode::Lr) {
        std::memcpy(scratchR1_, block.channelR, bytes);
        std::memset(scratchL1_, 0, bytes);
        std::memset(block.channelR, 0, bytes);
        // block.channelL already holds the dry left signal == branch0 L.
    } else {
        for (int i = 0; i < block.numSamples; ++i) {
            const float l = block.channelL[i];
            const float r = block.channelR[i];
            const float mid = (l + r) * 0.5f;
            const float side = (l - r) * 0.5f;
            block.channelL[i] = mid;
            block.channelR[i] = mid;
            scratchL1_[i] = side;
            scratchR1_[i] = -side;
        }
    }

    runBranch(0, block.channelL, block.channelR, block.numSamples, ctx);
    runBranch(1, scratchL1_, scratchR1_, block.numSamples, ctx);

    // Per-branch output gain + solo (mute non-soloed when any solo active).
    const bool anySolo = playback_->branch0Solo || playback_->branch1Solo;
    const float gain0 =
        ((!anySolo || playback_->branch0Solo) ? playback_->branch0Gain : 0.0f);
    const float gain1 =
        ((!anySolo || playback_->branch1Solo) ? playback_->branch1Gain : 0.0f);
    float peak0 = 0.0f;
    float peak1 = 0.0f;
    for (int i = 0; i < block.numSamples; ++i) {
        block.channelL[i] *= gain0;
        block.channelR[i] *= gain0;
        scratchL1_[i] *= gain1;
        scratchR1_[i] *= gain1;
        peak0 = std::max(peak0, std::max(std::abs(block.channelL[i]),
                                         std::abs(block.channelR[i])));
        peak1 = std::max(peak1, std::max(std::abs(scratchL1_[i]),
                                         std::abs(scratchR1_[i])));
    }

    // Decode.
    if (mode == SplitMode::Lr) {
        std::memcpy(block.channelR, scratchR1_, bytes);
    } else {
        for (int i = 0; i < block.numSamples; ++i) {
            const float midPrime = (block.channelL[i] + block.channelR[i]) * 0.5f;
            const float sidePrime = (scratchL1_[i] - scratchR1_[i]) * 0.5f;
            block.channelL[i] = midPrime + sidePrime;
            block.channelR[i] = midPrime - sidePrime;
        }
    }

    // Branch VU: leftLevel = branch0, rightLevel = branch1 (post-gain).
    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        auto& meter = ctx.deviceMeters[meterSlot];
        meter.inputPeakL.store(peak0, std::memory_order_relaxed);
        meter.inputPeakR.store(peak1, std::memory_order_relaxed);
        meter.inputPeak.store(std::max(peak0, peak1), std::memory_order_relaxed);
    }
}

} // namespace audioapp
