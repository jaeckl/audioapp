#include "audioapp/devices/processors/MultibandSplitProcessor.hpp"

#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/instances/MultibandSplitModel.hpp"

#include <algorithm>
#include <cstring>
#include <span>

namespace audioapp {

MultibandSplitProcessor::~MultibandSplitProcessor() {
    if (bufferArena_ != nullptr) {
        bufferArena_->release(bandL_, bandR_);
        bufferArena_->release(outL_, outR_);
    }
}

bool MultibandSplitProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bandL_ != nullptr && outL_ != nullptr) return true;
    auto [bL, bR] = ctx.scratch.ringBufferArena.allocate();
    auto [oL, oR] = ctx.scratch.ringBufferArena.allocate();
    if (bL == nullptr || oL == nullptr) {
        ctx.scratch.ringBufferArena.release(bL, bR);
        ctx.scratch.ringBufferArena.release(oL, oR);
        return false;
    }
    bandL_ = bL;
    bandR_ = bR;
    outL_ = oL;
    outR_ = oR;
    bufferArena_ = &ctx.scratch.ringBufferArena;
    return true;
}

void MultibandSplitProcessor::prepareFilters(double sampleRate) noexcept {
    if (sampleRate <= 0.0 || playback_ == nullptr) return;
    const int xoCount = std::max(0, playback_->bandCount - 1);
    if (std::abs(sampleRate - lastSr_) < 1.0e-6 && lastSr_ > 0.0) {
        for (int i = 0; i < xoCount && i < 3; ++i) {
            const float hz = playback_->crossoverHz[i];
            xoL_[i].setCutoffFrequency(hz);
            xoR_[i].setCutoffFrequency(hz);
        }
        return;
    }
    lastSr_ = sampleRate;
    juce::dsp::ProcessSpec spec;
    spec.sampleRate = sampleRate;
    spec.maximumBlockSize = static_cast<juce::uint32>(kScratchFrames);
    spec.numChannels = 1;
    for (int i = 0; i < 3; ++i) {
        xoL_[i].prepare(spec);
        xoR_[i].prepare(spec);
        if (i < xoCount) {
            const float hz = playback_->crossoverHz[i];
            xoL_[i].setCutoffFrequency(hz);
            xoR_[i].setCutoffFrequency(hz);
        }
        xoL_[i].reset();
        xoR_[i].reset();
    }
}

void MultibandSplitProcessor::runBand(int bandIndex, float* left, float* right,
                                      int numSamples, ProcessContext& ctx) noexcept {
    auto& runtime = bands_[bandIndex];
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
    DeviceChainOrchestrator::processChain(sub);
}

void MultibandSplitProcessor::accumulateBand(float* left, float* right, float gain,
                                             float* outL, float* outR, int numSamples,
                                             float& peak) noexcept {
    for (int s = 0; s < numSamples; ++s) {
        const float l = left[s] * gain;
        const float r = right[s] * gain;
        outL[s] += l;
        outR[s] += r;
        peak = std::max(peak, std::max(std::abs(l), std::abs(r)));
    }
}

void MultibandSplitProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    for (auto& band : bands_) band = BandRuntime{};
    playback_ = std::get<MultibandSplitParams>(params).playback;
    lastSr_ = 0.0;
    if (playback_ == nullptr) return;

    DeviceNodePlayback root;
    root.kind = kind();
    root.deviceId = deviceId();
    root.params = params;
    schedule_ = compileDeviceSubgraphTree(buildDeviceSubgraphTree(root));
    if (!schedule_.valid()) return;

    try {
        const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
        for (int b = 0; b < bandCount; ++b) {
            const auto& branch = playback_->bands[b];
            if (branch.deviceCount <= 0) continue;
            auto order = compileFusedChildExecutionOrder(
                schedule_,
                std::span<const DeviceNodePlayback>(
                    branch.devices, static_cast<size_t>(branch.deviceCount)));
            if (!order.valid()) continue;
            bands_[b].executionOrder = order;
            bands_[b].arena = std::make_unique<ProcessorArena>(branch.deviceCount);
            buildProcessorChain(branch.devices, branch.deviceCount, *bands_[b].arena);
        }
    } catch (...) {
        for (auto& band : bands_) band = BandRuntime{};
    }
}

bool MultibandSplitProcessor::updateNestedDevice(const DeviceNodePlayback& node,
                                                 bool paramsChanged) noexcept {
    if (playback_ == nullptr) return false;
    const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
    for (int b = 0; b < bandCount; ++b) {
        auto& runtime = bands_[b];
        if (!runtime.arena) continue;
        const auto& branch = playback_->bands[b];
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
            if (processor != nullptr && processor->updateNestedDevice(node, paramsChanged))
                return true;
        }
    }
    return false;
}

bool MultibandSplitProcessor::setNestedCompiledParameter(
    uint64_t processorNodeId, uint16_t parameterId, float value, ParameterUpdateRate rate,
    float startValue) noexcept {
    if (playback_ == nullptr) return false;
    const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
    for (int b = 0; b < bandCount; ++b) {
        auto& runtime = bands_[b];
        if (!runtime.arena) continue;
        for (int child = 0; child < playback_->bands[b].deviceCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->setCompiledParameter(parameterId, value, rate, startValue);
            if (processor->setNestedCompiledParameter(processorNodeId, parameterId, value, rate,
                                                      startValue))
                return true;
        }
    }
    return false;
}

bool MultibandSplitProcessor::setNestedResolvedAsset(
    uint64_t processorNodeId, const ResolvedAssetUpdate& update) noexcept {
    if (playback_ == nullptr) return false;
    const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
    for (int b = 0; b < bandCount; ++b) {
        auto& runtime = bands_[b];
        if (!runtime.arena) continue;
        for (int child = 0; child < playback_->bands[b].deviceCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->applyResolvedAsset(update);
            if (processor->setNestedResolvedAsset(processorNodeId, update)) return true;
        }
    }
    return false;
}

bool MultibandSplitProcessor::readNestedEffectiveParameter(
    uint64_t processorNodeId, uint16_t parameterId, float& value,
    float* automationBase) const noexcept {
    if (playback_ == nullptr) return false;
    const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
    for (int b = 0; b < bandCount; ++b) {
        const auto& runtime = bands_[b];
        if (!runtime.arena) continue;
        for (int child = 0; child < playback_->bands[b].deviceCount; ++child) {
            const auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->readEffectiveParameter(parameterId, value, automationBase);
            if (processor->readNestedEffectiveParameter(processorNodeId, parameterId, value,
                                                        automationBase))
                return true;
        }
    }
    return false;
}

void MultibandSplitProcessor::bindCompiledParameterSpans(
    const AutomationClipPlayback* clips, int clipCount, const ModulationEdgePlayback* edges,
    int edgeCount) noexcept {
    DeviceProcessor::bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    if (playback_ == nullptr) return;
    const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
    for (int b = 0; b < bandCount; ++b) {
        auto& runtime = bands_[b];
        if (!runtime.arena) continue;
        for (int child = 0; child < playback_->bands[b].deviceCount; ++child)
            if (auto* processor = runtime.arena->get(child))
                processor->bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    }
}

void MultibandSplitProcessor::resetPlaybackState() noexcept {
    for (auto& runtime : bands_) {
        if (runtime.arena) resetPlaybackStateInArena(*runtime.arena);
    }
    for (int i = 0; i < 3; ++i) {
        xoL_[i].reset();
        xoR_[i].reset();
    }
}

void MultibandSplitProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (playback_ == nullptr || block.numSamples <= 0 || block.numSamples > kScratchFrames)
        return;

    prepareFilters(ctx.sampleRate);
    if (!ensureBuffers(ctx)) return;
    const int n = block.numSamples;
    const size_t bytes = static_cast<size_t>(n) * sizeof(float);
    const int bandCount = std::clamp(playback_->bandCount, 2, kMaxMbBands);
    const int xoCount = bandCount - 1;

    std::memcpy(workL_, block.channelL, bytes);
    std::memcpy(workR_, block.channelR, bytes);
    std::memset(outL_, 0, bytes);
    std::memset(outR_, 0, bytes);

    float peak0 = 0.0f;
    float peak1 = 0.0f;
    for (int i = 0; i < xoCount; ++i) {
        for (int s = 0; s < n; ++s) {
            float lowL = 0.0f, highL = 0.0f, lowR = 0.0f, highR = 0.0f;
            xoL_[i].processSample(0, workL_[s], lowL, highL);
            xoR_[i].processSample(0, workR_[s], lowR, highR);
            bandL_[s] = lowL;
            bandR_[s] = lowR;
            workL_[s] = highL;
            workR_[s] = highR;
        }
        runBand(i, bandL_, bandR_, n, ctx);
        float peak = 0.0f;
        accumulateBand(bandL_, bandR_, playback_->bandGain[i], outL_, outR_, n, peak);
        if (i == 0) peak0 = peak;
        else if (i == 1) peak1 = peak;
    }

    runBand(bandCount - 1, workL_, workR_, n, ctx);
    float lastPeak = 0.0f;
    accumulateBand(workL_, workR_, playback_->bandGain[bandCount - 1], outL_, outR_, n,
                   lastPeak);
    if (bandCount == 2) peak1 = lastPeak;
    else if (xoCount == 0) peak0 = lastPeak;

    std::memcpy(block.channelL, outL_, bytes);
    std::memcpy(block.channelR, outR_, bytes);

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        auto& meter = ctx.deviceMeters[meterSlot];
        meter.inputPeakL.store(peak0, std::memory_order_relaxed);
        meter.inputPeakR.store(peak1, std::memory_order_relaxed);
        meter.inputPeak.store(std::max(peak0, peak1), std::memory_order_relaxed);
    }
}

} // namespace audioapp
