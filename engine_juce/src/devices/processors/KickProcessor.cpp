#include "audioapp/devices/processors/KickProcessor.hpp"
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

bool isKickNoteAudible(const audioapp::KickMidiNoteRegion& note,
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

} // namespace

namespace audioapp {

void mixKickMidiNotesBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const KickMidiNoteRegion* notes,
                           int noteCount,
                           const KickGeneratorParams& params,
                           KickGeneratorRuntime& runtime,
                           const InstrumentModulationContext* instMod,
                           const CommonControlBlock* commonControls,
                           uint16_t deviceIndex) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = normalizedToAmpDecaySec(params.kickDecay) + 0.05f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
        int activeNoteIndex = -1;
        int activePitch = 36;
        float activeVelocity = 100.0f;
        double activeElapsed = 0.0;

        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            bool inRelease = false;
            if (!isKickNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
                continue;
            }
            activeNoteKey = note.noteKey;
            activeNoteIndex = noteIndex;
            activePitch = note.pitch;
            activeVelocity = note.velocity;
            activeElapsed = elapsedSeconds;
        }

        if (activeNoteKey < 0) {
            runtime.voice.active = 0;
            runtime.lastNoteKey = -1;
            continue;
        }

        if (runtime.lastNoteKey != activeNoteKey || runtime.voice.active == 0) {
            triggerKickVoice(runtime.voice, activePitch, activeVelocity);
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.kickVelocity * (1.0f - vel);
        float panelGain = commonControls != nullptr ? commonControls->gainAt(frame) : 1.0f;
        if (instMod != nullptr && activeNoteIndex >= 0) {
            const auto& note = notes[activeNoteIndex];
            const NoteModKey key = noteModKeyFromRegion(
                note.pitch, note.clipStartBeat, note.noteStartBeat);
            const ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
            panelGain = applyPerNoteCommonGain(panelGain,
                                               deviceIndex,
                                               activeElapsed,
                                               -1.0,
                                               key,
                                               evalCtx,
                                               *instMod);
        }
        monoOut[frame] += kickGeneratorSample(runtime.voice, params, sampleRate, velGain)
            * panelGain;
    }
}

void KickProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!ctx.suppressInstruments && ctx.noteCount > 0) {
        const auto& kp = std::get<KickGeneratorParams>(*ctx.modulatedParams);
        const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
        for (int i = 0; i < regionCount; ++i) {
            const MidiPlaybackNote& note = ctx.notes[i];
            ctx.scratch.kickRegions[i] = KickMidiNoteRegion{
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
            deviceHasPerNoteModEdges(
                ctx.processorNodeId, static_cast<uint16_t>(ctx.deviceIndex),
                ctx.modEdges, ctx.modEdgeCount, ctx.modulators, ctx.lfoCount);
        mixKickMidiNotesBlock(
            ctx.scratch.scratch,
            block.numSamples,
            ctx.sampleRate,
            ctx.bpm,
            ctx.playheadBeat,
            ctx.scratch.kickRegions,
            regionCount,
            kp,
            runtime_,
            instModPtr,
            bakePanelGain ? &ctx.commonControls : nullptr,
            di
        );
        StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                            ctx.commonControls, !bakePanelGain);
    }
}

} // namespace audioapp
