#include "audioapp/devices/processors/GranularProcessor.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

namespace audioapp {

void GranularProcessor::resetPlaybackState() noexcept {
    formantState_ = GranularFormantFilterState{};
}

void GranularProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || !ctx.modulatedParams) {
        return;
    }
    const auto& p = std::get<GranularParams>(*ctx.modulatedParams);
    if (!p.pcm || p.frameCount < 4 || ctx.noteCount <= 0) {
        return;
    }

    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const uint64_t nodeId =
        ctx.processorNodeId != 0 ? ctx.processorNodeId : stableProcessorNodeId;
    const bool hasAuto =
        nodeHasDspAutomation(nodeId, di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0;
    const InstrumentModulationContext* instModPtr = nullptr;
    InstrumentModulationContext instMod;
    if (hasMod && ctx.modulators != nullptr) {
        instMod = ctx.instrumentModulation();
        instModPtr = &instMod;
    }

    mixGranularMidiNotesBlock(block.channelL,
                              block.channelR,
                              block.numSamples,
                              ctx.sampleRate,
                              ctx.bpm,
                              ctx.playheadBeat,
                              ctx.notes,
                              ctx.noteCount,
                              p,
                              formantState_,
                              hasAuto ? ctx.automationClips : nullptr,
                              hasAuto ? ctx.automationClipCount : 0,
                              hasAuto ? &di : nullptr,
                              hasMod ? ctx.lfoValues : nullptr,
                              hasMod ? ctx.lfoCount : 0,
                              hasMod ? block.numSamples : 0,
                              hasMod ? ctx.modEdges : nullptr,
                              hasMod ? ctx.modEdgeCount : 0,
                              hasMod ? &di : nullptr,
                              instModPtr,
                              &ctx.commonControls,
                              nodeId);
}

} // namespace audioapp
