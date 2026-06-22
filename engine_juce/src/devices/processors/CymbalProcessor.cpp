#include "audioapp/devices/processors/CymbalProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cstring>
#include <algorithm>
#include <cmath>

namespace audioapp {

void CymbalProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!ctx.suppressInstruments && ctx.noteCount > 0) {
        const auto& cyp = std::get<CymbalGeneratorParams>(*ctx.modulatedParams);
        const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
        for (int i = 0; i < regionCount; ++i) {
            const MidiPlaybackNote& note = ctx.notes[i];
            ctx.scratch.cymbalRegions[i] = CymbalMidiNoteRegion{
                note.pitch,
                i,
                note.clipStartBeat,
                note.clipLengthBeats,
                note.noteStartBeat,
                note.noteDurationBeats,
                note.velocity
            };
        }
        std::memset(ctx.scratch.tempStereoL, 0, static_cast<size_t>(block.numSamples) * sizeof(float));
        std::memset(ctx.scratch.tempStereoR, 0, static_cast<size_t>(block.numSamples) * sizeof(float));
        mixCymbalMidiNotesBlockStereo(
            ctx.scratch.tempStereoL,
            ctx.scratch.tempStereoR,
            block.numSamples,
            ctx.sampleRate,
            ctx.bpm,
            ctx.playheadBeat,
            ctx.scratch.cymbalRegions,
            regionCount,
            cyp,
            runtime_,
            ctx.scratch.perFrameGain
        );
        for (int f = 0; f < block.numSamples; ++f) {
            const float angle = std::clamp(ctx.scratch.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
            block.channelL[f] += ctx.scratch.tempStereoL[f] * std::cos(angle) + ctx.scratch.tempStereoR[f] * std::cos(angle);
            block.channelR[f] += ctx.scratch.tempStereoL[f] * std::sin(angle) + ctx.scratch.tempStereoR[f] * std::sin(angle);
        }
    }
}

} // namespace audioapp