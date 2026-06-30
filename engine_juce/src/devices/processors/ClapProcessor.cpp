#include "audioapp/devices/processors/ClapProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace {

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

float clapNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

bool isClapNoteAudible(const audioapp::ClapMidiNoteRegion& note,
                       double beat,
                       int bpm,
                       float releaseSec,
                       double& elapsedSecondsOut,
                       bool& inReleaseOut) noexcept {
    if (bpm <= 0) {
        return false;
    }
    const double loopedBeat = audioapp::beatWithinClipContent(
        beat,
        note.clipStartBeat,
        note.clipLengthBeats,
        note.contentLengthBeats,
        note.loopContent);
    if (loopedBeat < 0.0) {
        return false;
    }
    const double noteEnd = note.noteStartBeat + note.noteDurationBeats;
    const double releaseBeats =
        static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    if (loopedBeat < note.noteStartBeat) {
        return false;
    }
    const double elapsedBeats = loopedBeat - note.noteStartBeat;
    elapsedSecondsOut = elapsedBeats * 60.0 / static_cast<double>(bpm);
    inReleaseOut = loopedBeat >= noteEnd;
    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

void mixClapMidiNotesBlock(float* monoOut,
                            int numFrames,
                            double sampleRate,
                            int bpm,
                            double playheadStartBeat,
                            const audioapp::ClapMidiNoteRegion* notes,
                            int noteCount,
                            const audioapp::ClapGeneratorParams& params,
                            audioapp::ClapGeneratorRuntime& runtime,
                            const audioapp::InstrumentModulationContext* instMod = nullptr,
                            const float* perFramePanelGain = nullptr,
                            uint16_t deviceIndex = 0) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }
    const float releaseSec = 0.12f + (1.0f - std::clamp(params.clapDecay, 0.0f, 1.0f)) * 0.38f + 0.08f;
    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        int activeNoteKey = -1;
        int activeNoteIndex = -1;
        float activeVelocity = 100.0f;
        double activeElapsed = 0.0;
        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            bool inRelease = false;
            if (!isClapNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
                continue;
            }
            activeNoteKey = note.noteKey;
            activeNoteIndex = noteIndex;
            activeVelocity = note.velocity;
            activeElapsed = elapsedSeconds;
        }
        if (activeNoteKey < 0) {
            runtime.voice.active = 0;
            runtime.lastNoteKey = -1;
            continue;
        }
        if (runtime.lastNoteKey != activeNoteKey || runtime.voice.active == 0) {
            triggerClapVoice(runtime.voice, activeVelocity, params);
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;
        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.clapVelocity * (1.0f - vel);
        float panelGain = perFramePanelGain != nullptr ? perFramePanelGain[frame] : 1.0f;
        if (instMod != nullptr && activeNoteIndex >= 0) {
            const auto& note = notes[activeNoteIndex];
            const audioapp::NoteModKey key = audioapp::noteModKeyFromRegion(
                note.pitch, note.clipStartBeat, note.noteStartBeat);
            const audioapp::ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
            panelGain = audioapp::applyPerNoteCommonGain(panelGain,
                                                         deviceIndex,
                                                         activeElapsed,
                                                         key,
                                                         evalCtx,
                                                         *instMod);
        }
        monoOut[frame] += audioapp::clapGeneratorSample(runtime.voice, params, sampleRate, velGain)
            * panelGain;
    }
}

} // anonymous namespace

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
                note.velocity,
                note.loopContent,
                note.contentLengthBeats,
            };
        }
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
        mixClapMidiNotesBlock(
            ctx.scratch.scratch,
            block.numSamples,
            ctx.sampleRate,
            ctx.bpm,
            ctx.playheadBeat,
            ctx.scratch.clapRegions,
            regionCount,
            cp,
            runtime_,
            instModPtr,
            ctx.scratch.perFrameGain,
            di
        );
        StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                             bakePanelGain ? nullptr : ctx.scratch.perFrameGain,
                                             ctx.scratch.perFramePan);
    }
}

} // namespace audioapp