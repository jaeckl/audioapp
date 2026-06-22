#include "audioapp/devices/processors/SamplerProcessor.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <algorithm>
#include <cstring>

namespace audioapp {

void SamplerProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments) {
        return;
    }

    const auto& baseParams = std::get<SamplerParams>(*ctx.modulatedParams);
    if (baseParams.samplerPcm == nullptr || ctx.noteCount <= 0) {
        return;
    }

    const double beatsPerFrame = (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.samplerRegions[i] = SamplerMidiNoteRegion{
            note.pitch, note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity,
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    std::memset(ctx.scratch.samplerNoteFilterStates, 0, sizeof(ctx.scratch.samplerNoteFilterStates));
    BiquadState* effectiveNoteFilters = samplerFilterStates_;

    const auto render = [&](int sub, int subLen, double subBeat, const SamplerParams& p) {
        mixSamplerMidiNotesBlock(ctx.scratch.scratch + sub, subLen, ctx.sampleRate, ctx.bpm, subBeat,
            ctx.scratch.samplerRegions, regionCount, SamplerInstrumentPlayback{
                p.samplerPcm, p.samplerFrameCount, p.samplerPcmSampleRate,
                kInstrumentOutputGain, p.rootPitch, p.rootFineTune,
                p.attack, p.decay, p.sustain, p.release,
                p.filterCutoff, p.filterQ, p.filterMode,
                p.filterEnvAmount, p.filterAttack, p.filterDecay, p.filterSustain, p.filterRelease,
                p.trimStartFrame, p.trimEndFrame, p.regionStartFrame, p.regionEndFrame,
                p.playbackMode, nullptr, effectiveNoteFilters, regionCount,
            });
    };

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
            const auto p = std::get<SamplerParams>(subParams);
            render(sub, subLen, subBeat, p);
        }
    } else {
        render(0, block.numSamples, ctx.playheadBeat, baseParams);
    }

    multiplyPerFrameGain(ctx.scratch.scratch, block.numSamples, ctx.scratch.perFrameGain);
    mixStereoPerFramePan(block.channelL, block.channelR, ctx.scratch.scratch, block.numSamples, ctx.scratch.perFramePan);
}

} // namespace audioapp