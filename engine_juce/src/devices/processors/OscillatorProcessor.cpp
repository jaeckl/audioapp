#include "audioapp/devices/processors/OscillatorProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cstring>
#include <cmath>

namespace audioapp {

void OscillatorProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments) {
        return;
    }

    const double beatsPerFrame = (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;

    auto midiActiveFrequencyHz = [&](float idleFrequencyHz) noexcept {
        auto noteActive = [](const MidiPlaybackNote& note, double beat) {
            return isMidiNoteActiveInClip(
                beat,
                note.clipStartBeat,
                note.clipLengthBeats,
                note.contentLengthBeats,
                note.loopContent,
                note.noteStartBeat,
                note.noteDurationBeats);
        };
        int pitch = -1;
        for (int i = 0; i < ctx.noteCount; ++i) {
            if (!noteActive(ctx.notes[i], ctx.playheadBeat)) continue;
            pitch = ctx.notes[i].pitch;
        }
        if (pitch >= 0) {
            // MIDI note active: apply modulation offset on top of MIDI note pitch.
            // idleFrequencyHz already includes LFO/automation modulation from
            // dspParamsAtFrame. Compute the offset from the base frequency.
            const float baseHz = std::get<OscillatorParams>(storedParams()).frequencyHz;
            const float modOffset = idleFrequencyHz - baseHz;
            return std::max(20.0f, midiNoteToHz(pitch) + modOffset);
        }
        return idleFrequencyHz;
    };

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0;
    const InstrumentModulationContext* instModPtr = nullptr;
    InstrumentModulationContext instMod;
    if (hasMod && ctx.modulators != nullptr) {
        instMod = ctx.instrumentModulation();
        instModPtr = &instMod;
    }
    const bool bakePanelGain = instModPtr != nullptr &&
        deviceHasPerNoteModEdges(di, ctx.modEdges, ctx.modEdgeCount, ctx.modulators, ctx.lfoCount);

    if (ctx.needsSubBlocks) {
        DeviceNodePlayback tmpNode;
        tmpNode.params = *ctx.modulatedParams;
        tmpNode.kind = kind();
        for (int sub = 0; sub < block.numSamples; sub += kAutomationSubBlockFrames) {
            const int subLen = std::min(kAutomationSubBlockFrames, block.numSamples - sub);
            const double subBeat = ctx.playheadBeat + static_cast<double>(sub) * beatsPerFrame;
            auto subParams = DeviceChainAutomationModulation::dspParamsAtFrame(
                tmpNode, ctx.deviceIndex, subBeat, sub, block.numSamples,
                ctx.automationClips, ctx.automationClipCount, ctx.lfoValues, ctx.lfoCount,
                ctx.modEdges, ctx.modEdgeCount);
            auto p = std::get<OscillatorParams>(subParams);
            p.frequencyHz = midiActiveFrequencyHz(p.frequencyHz);
            if (p.frequencyHz > 0.0f) {
                addSineBlock(ctx.scratch.scratch + sub, subLen, ctx.sampleRate, p.frequencyHz,
                             oscillatorPhase_, kInstrumentOutputGain);
            }
        }
    } else {
        auto p = std::get<OscillatorParams>(*ctx.modulatedParams);
        p.frequencyHz = midiActiveFrequencyHz(p.frequencyHz);
        if (p.frequencyHz > 0.0f) {
            addSineBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, p.frequencyHz,
                         oscillatorPhase_, kInstrumentOutputGain);
        }
    }

    if (instModPtr != nullptr && bakePanelGain && ctx.noteCount > 0) {
        for (int frame = 0; frame < block.numSamples; ++frame) {
            const double beat = ctx.playheadBeat + static_cast<double>(frame) * beatsPerFrame;
            const MidiPlaybackNote* activeNote = nullptr;
            for (int i = 0; i < ctx.noteCount; ++i) {
                if (!isMidiNoteActiveInClip(
                        beat,
                        ctx.notes[i].clipStartBeat,
                        ctx.notes[i].clipLengthBeats,
                        ctx.notes[i].contentLengthBeats,
                        ctx.notes[i].loopContent,
                        ctx.notes[i].noteStartBeat,
                        ctx.notes[i].noteDurationBeats)) {
                    continue;
                }
                activeNote = &ctx.notes[i];
            }
            if (activeNote == nullptr) {
                continue;
            }
            const double loopedBeat = beatWithinClipContent(
                beat,
                activeNote->clipStartBeat,
                activeNote->clipLengthBeats,
                activeNote->contentLengthBeats,
                activeNote->loopContent);
            const double elapsedSec =
                (loopedBeat - activeNote->noteStartBeat) * 60.0
                / static_cast<double>(std::max(ctx.bpm, 1));
            const NoteModKey key = noteModKeyFromMidi(*activeNote);
            const ModulationEvalContext evalCtx = instModPtr->evalContextForFrame(frame);
            const float panelGain = applyPerNoteCommonGain(ctx.scratch.perFrameGain[frame],
                                                           di,
                                                           elapsedSec,
                                                           key,
                                                           evalCtx,
                                                           *instModPtr);
            ctx.scratch.scratch[frame] *= panelGain;
        }
    }

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         bakePanelGain ? nullptr : ctx.scratch.perFrameGain,
                                         ctx.scratch.perFramePan);
}

} // namespace audioapp