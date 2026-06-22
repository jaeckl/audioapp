#include "audioapp/devices/processors/PhaseModSynthProcessor.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <algorithm>
#include <cstring>

namespace audioapp {

void PhaseModSynthProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || ctx.noteCount <= 0) {
        return;
    }

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.phaseModRegions[i] = PhaseModSynthMidiNoteRegion{
            note.pitch, note.pitch,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const bool hasAuto = nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0 &&
                        DeviceChainAutomationModulation::nodeHasDspModulation(di, ctx.modEdges, ctx.modEdgeCount);

    mixPhaseModMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.phaseModRegions, regionCount,
        std::get<PhaseModSynthParams>(*ctx.modulatedParams), runtime,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr);

    multiplyPerFrameGain(ctx.scratch.scratch, block.numSamples, ctx.scratch.perFrameGain);
    mixStereoPerFramePan(block.channelL, block.channelR, ctx.scratch.scratch, block.numSamples, ctx.scratch.perFramePan);
}

} // namespace audioapp