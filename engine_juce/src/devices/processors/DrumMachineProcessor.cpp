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
    try {
        for (int note = 0; note < 128; ++note) {
            const auto& pad = playback_->pads[note];
            if (pad.deviceCount <= 0) continue;
            PadRuntime runtime;
            runtime.note = note;
            runtime.padIndex = note;
            runtime.arena = std::make_unique<ProcessorArena>();
            buildProcessorChain(pad.devices, pad.deviceCount, *runtime.arena);
            pads_.push_back(std::move(runtime));
        }
    } catch (...) {
        pads_.clear();
    }
}

void DrumMachineProcessor::resetPlaybackState() noexcept {
    for (auto& pad : pads_) {
        resetPlaybackStateInArena(*pad.arena);
        pad.tailActive = false;
    }
}

void DrumMachineProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (playback_ == nullptr || block.numSamples <= 0 || block.numSamples > kScratchFrames) return;
    bool hasSolo = false;
    for (const auto& runtime : pads_) hasSolo |= playback_->pads[runtime.padIndex].solo;

    const double beatsPerFrame = (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;
    const double blockEndBeat = ctx.playheadBeat + beatsPerFrame * (block.numSamples - 1);

    for (auto& runtime : pads_) {
        const auto& pad = playback_->pads[runtime.padIndex];
        if (pad.muted || (hasSolo && !pad.solo)) continue;

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

        if (triggersNow && pad.chokeGroup > 0) {
            for (auto& other : pads_) {
                if (&other != &runtime && playback_->pads[other.padIndex].chokeGroup == pad.chokeGroup) {
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
        AutomationClipPlayback padAutomation[16]{};
        int padAutomationCount = 0;
        if (ctx.automationClips != nullptr) {
            for (int a = 0; a < ctx.automationClipCount && padAutomationCount < 16; ++a) {
                for (int child = 0; child < pad.deviceCount; ++child) {
                    if (ctx.automationClips[a].deviceIndex !=
                        pad.devices[child].automationTargetIndex) continue;
                    padAutomation[padAutomationCount] = ctx.automationClips[a];
                    padAutomation[padAutomationCount].deviceIndex = static_cast<uint16_t>(child);
                    ++padAutomationCount;
                    break;
                }
            }
        }
        sub.automationClips = padAutomationCount > 0 ? padAutomation : nullptr;
        sub.automationClipCount = padAutomationCount;
        DeviceChainOrchestrator::processChain(sub);

        runtime.tailActive = false;
        for (int i = 0; i < runtime.arena->size(); ++i) {
            if (auto* processor = runtime.arena->get(i)) runtime.tailActive |= processor->hasActiveTail();
        }
        const float leftGain = pad.gain * (pad.pan <= 0.5f ? 1.0f : 2.0f * (1.0f - pad.pan));
        const float rightGain = pad.gain * (pad.pan >= 0.5f ? 1.0f : 2.0f * pad.pan);
        for (int frame = 0; frame < block.numSamples; ++frame) {
            block.channelL[frame] += padLeft_[frame] * leftGain;
            block.channelR[frame] += padRight_[frame] * rightGain;
        }
    }
}

} // namespace audioapp
