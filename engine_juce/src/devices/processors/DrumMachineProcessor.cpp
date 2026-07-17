#include "audioapp/devices/processors/DrumMachineProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

void DrumMachineProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    pads_.clear();
    playback_ = std::get<DrumMachineParams>(params).playback;
    if (playback_ == nullptr) return;
    DeviceNodePlayback root;
    root.kind = kind();
    root.deviceId = deviceId();
    root.params = params;
    schedule_ = compileDeviceSubgraphTree(buildDeviceSubgraphTree(root));
    if (!schedule_.valid()) return;
    try {
        for (int note = 0; note < 128; ++note) {
            const auto& pad = playback_->pads[note];
            if (pad.deviceCount <= 0) continue;
            PadRuntime runtime;
            runtime.note = note;
            runtime.padIndex = note;
            runtime.gain = pad.gain;
            runtime.pan = pad.pan;
            runtime.muted = pad.muted;
            runtime.solo = pad.solo;
            runtime.chokeGroup = pad.chokeGroup;
            runtime.executionOrder = compileFusedChildExecutionOrder(
                schedule_,
                std::span<const DeviceNodePlayback>(pad.devices,
                                                     static_cast<size_t>(pad.deviceCount)));
            if (!runtime.executionOrder.valid()) continue;
            runtime.arena = std::make_unique<ProcessorArena>(pad.deviceCount);
            buildProcessorChain(pad.devices, pad.deviceCount, *runtime.arena);
            pads_.push_back(std::move(runtime));
        }
    } catch (...) {
        pads_.clear();
    }
}

bool DrumMachineProcessor::updateNestedDevice(const DeviceNodePlayback& node,
                                               bool paramsChanged) noexcept {
    if (playback_ == nullptr) return false;
    for (auto& runtime : pads_) {
        const auto& pad = playback_->pads[runtime.padIndex];
        for (int child = 0; child < pad.deviceCount; ++child) {
            auto* processor = runtime.arena ? runtime.arena->get(child) : nullptr;
            if (pad.devices[child].deviceId == node.deviceId) {
                if (processor == nullptr) return false;
                processor->bypassed = node.bypassed;
                processor->gain = node.gain;
                processor->pan = node.pan;
                processor->outputMix = node.outputMix;
                processor->outputWidth = node.outputWidth;
                if (paramsChanged) {
                    if (node.kind == DeviceNodeKind::Sampler) {
                        auto params = node.params;
                        std::get<SamplerParams>(params).rootPitch = runtime.note;
                        processor->voicePolicy = pad.devices[child].voicePolicy;
                        processor->initParams(params);
                    } else {
                        processor->applyPlaybackNode(node);
                    }
                }
                return true;
            }
            if (processor != nullptr && processor->updateNestedDevice(node, paramsChanged))
                return true;
        }
    }
    return false;
}

bool DrumMachineProcessor::setNestedCompiledParameter(uint64_t processorNodeId,
                                                       uint16_t parameterId,
                                                       float value,
                                                       ParameterUpdateRate rate) noexcept {
    for (auto& runtime : pads_) {
        const int childCount = playback_ ? playback_->pads[runtime.padIndex].deviceCount : 0;
        for (int child = 0; runtime.arena && child < childCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->setCompiledParameter(parameterId, value, rate);
            if (processor->setNestedCompiledParameter(processorNodeId, parameterId, value, rate))
                return true;
        }
    }
    return false;
}

bool DrumMachineProcessor::readNestedEffectiveParameter(
    uint64_t processorNodeId, uint16_t parameterId, float& value) const noexcept {
    for (const auto& runtime : pads_) {
        const int childCount = playback_ ? playback_->pads[runtime.padIndex].deviceCount : 0;
        for (int child = 0; runtime.arena && child < childCount; ++child) {
            const auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->readEffectiveParameter(parameterId, value);
            if (processor->readNestedEffectiveParameter(processorNodeId, parameterId, value))
                return true;
        }
    }
    return false;
}

void DrumMachineProcessor::bindCompiledParameterSpans(
    const AutomationClipPlayback* clips, int clipCount,
    const ModulationEdgePlayback* edges, int edgeCount) noexcept {
    DeviceProcessor::bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    for (auto& runtime : pads_) {
        const int childCount = playback_ ? playback_->pads[runtime.padIndex].deviceCount : 0;
        for (int child = 0; runtime.arena && child < childCount; ++child)
            if (auto* processor = runtime.arena->get(child))
                processor->bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    }
}

bool DrumMachineProcessor::updateDrumPadParameter(
    int note, std::string_view parameterId, float value) noexcept {
    if (playback_ == nullptr || note < 0 || note >= 128) return false;
    const auto it = std::find_if(pads_.begin(), pads_.end(),
        [note](const PadRuntime& runtime) { return runtime.padIndex == note; });
    if (it == pads_.end()) return false;
    if (parameterId == "gain") it->gain = std::clamp(value, 0.0f, 2.0f);
    else if (parameterId == "pan") it->pan = std::clamp(value, 0.0f, 1.0f);
    else if (parameterId == "mute") it->muted = value >= 0.5f;
    else if (parameterId == "solo") it->solo = value >= 0.5f;
    else if (parameterId == "chokeGroup")
        it->chokeGroup = std::clamp(static_cast<int>(std::lround(value)), 0, 16);
    else return false;
    return true;
}

void DrumMachineProcessor::resetPlaybackState() noexcept {
    for (auto& pad : pads_) {
        resetPlaybackStateInArena(*pad.arena);
        pad.tailActive = false;
    }
}

void DrumMachineProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (playback_ == nullptr || !schedule_.valid() ||
        block.numSamples <= 0 || block.numSamples > kScratchFrames) return;
    bool hasSolo = false;
    for (const auto& runtime : pads_) hasSolo |= runtime.solo;

    const double beatsPerFrame = (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;
    const double blockEndBeat = ctx.playheadBeat + beatsPerFrame * (block.numSamples - 1);

    for (auto& runtime : pads_) {
        const auto& pad = playback_->pads[runtime.padIndex];
        if (runtime.muted || (hasSolo && !runtime.solo)) continue;

        int routedCount = 0;
        bool triggersNow = false;
        for (int i = 0; i < ctx.noteCount && routedCount < kMaxInstrumentRegions; ++i) {
            const auto& note = ctx.notes[i];
            if (note.pitch != runtime.note) continue;
            const double startContent = beatWithinClipContent(ctx.playheadBeat, note.clipStartBeat,
                note.clipLengthBeats, note.contentLengthBeats, note.loopContent);
            const double endContent = beatWithinClipContent(blockEndBeat, note.clipStartBeat,
                note.clipLengthBeats, note.contentLengthBeats, note.loopContent);
            const double tailBeats = 4.0 * static_cast<double>(std::max(ctx.bpm, 1)) / 60.0;
            const bool relevant =
                (startContent >= note.noteStartBeat && startContent <= note.noteStartBeat + note.noteDurationBeats + tailBeats) ||
                (endContent >= note.noteStartBeat && endContent <= note.noteStartBeat + note.noteDurationBeats + tailBeats) ||
                (startContent <= note.noteStartBeat && endContent >= note.noteStartBeat);
            if (!relevant) continue;
            triggersNow |= startContent <= note.noteStartBeat && endContent >= note.noteStartBeat;
            routedNotes_[routedCount++] = note;
        }

        if (triggersNow && runtime.chokeGroup > 0) {
            for (auto& other : pads_) {
                if (&other != &runtime && other.chokeGroup == runtime.chokeGroup) {
                    resetPlaybackStateInArena(*other.arena);
                    other.tailActive = false;
                }
            }
        }
        if (routedCount == 0 && !runtime.tailActive) continue;

        std::memset(padLeft_, 0, static_cast<size_t>(block.numSamples) * sizeof(float));
        std::memset(padRight_, 0, static_cast<size_t>(block.numSamples) * sizeof(float));
        DeviceChainOrchestrator::Context sub(*runtime.arena, ctx.scratch);
        sub.trackLeft = padLeft_;
        sub.trackRight = padRight_;
        sub.numFrames = block.numSamples;
        sub.sampleRate = ctx.sampleRate;
        sub.bpm = ctx.bpm;
        sub.playheadStartBeat = ctx.playheadBeat;
        sub.notes = routedNotes_;
        sub.noteCount = routedCount;
        sub.wavetableBank = ctx.wavetableBank;
        sub.suppressInstruments = ctx.suppressInstruments;
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

        runtime.tailActive = false;
        for (int i = 0; i < runtime.arena->size(); ++i) {
            if (auto* processor = runtime.arena->get(i)) runtime.tailActive |= processor->hasActiveTail();
        }
        const float leftGain = runtime.gain * (runtime.pan <= 0.5f ? 1.0f : 2.0f * (1.0f - runtime.pan));
        const float rightGain = runtime.gain * (runtime.pan >= 0.5f ? 1.0f : 2.0f * runtime.pan);
        for (int frame = 0; frame < block.numSamples; ++frame) {
            block.channelL[frame] += padLeft_[frame] * leftGain;
            block.channelR[frame] += padRight_[frame] * rightGain;
        }
    }
}

} // namespace audioapp
