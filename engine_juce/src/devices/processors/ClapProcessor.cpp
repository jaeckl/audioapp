#include "audioapp/devices/processors/ClapProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cstring>

namespace audioapp {

void ClapProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!ctx.suppressInstruments && ctx.noteCount > 0) {
        const auto& cp = std::get<ClapGeneratorParams>(*ctx.modulatedParams);
        const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
        for (int i = 0; i < regionCount; ++i) {
            const MidiPlaybackNote& note = ctx.notes[i];
            ctx.scratch.clapRegions[i] = ClapMidiNoteRegion{
                note.pitch,
                i,
                note.clipStartBeat,
                note.clipLengthBeats,
                note.noteStartBeat,
                note.noteDurationBeats,
                note.velocity
            };
        }
        std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));
        mixClapMidiNotesBlock(
            ctx.scratch.scratch,
            block.numSamples,
            ctx.sampleRate,
            ctx.bpm,
            ctx.playheadBeat,
            ctx.scratch.clapRegions,
            regionCount,
            cp,
            runtime_
        );
        multiplyPerFrameGain(ctx.scratch.scratch, block.numSamples, ctx.scratch.perFrameGain);
        mixStereoPerFramePan(block.channelL, block.channelR, ctx.scratch.scratch, block.numSamples, ctx.scratch.perFramePan);
    }
}

} // namespace audioapp