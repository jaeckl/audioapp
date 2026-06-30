#include "audioapp/devices/processors/SnareProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/SnareAlgorithm.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace {

constexpr double kTwoPi = 6.28318530718;

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

float xorshiftNoise(uint32_t& state) noexcept {
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    return static_cast<float>(state) * (1.0f / 2147483648.0f) - 1.0f;
}

uint32_t seedFromPitch(int pitch) noexcept {
    return 0x9E3779B9u ^ static_cast<uint32_t>(pitch) * 0x85EBCA6Bu;
}

bool isSnareNoteAudible(const audioapp::SnareMidiNoteRegion& note,
                        double beat,
                        int bpm,
                        float releaseSec,
                        double& elapsedSecondsOut,
                        bool& inReleaseOut) noexcept {
    using namespace audioapp;
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

float normalizedToAmpDecaySec(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 0.15f + (1.0f - clamped) * 0.35f;
}

float pitchTrackRatio(int pitch) noexcept {
    return std::pow(2.0f, static_cast<float>(pitch - 38) / 12.0f);
}

void mixSnareMidiNotesBlock(float* monoOut,
                            int numFrames,
                            double sampleRate,
                            int bpm,
                            double playheadStartBeat,
                            const audioapp::SnareMidiNoteRegion* notes,
                            int noteCount,
                            const audioapp::SnareGeneratorParams& params,
                            audioapp::SnareGeneratorRuntime& runtime,
                            const audioapp::InstrumentModulationContext* instMod = nullptr,
                            const float* perFramePanelGain = nullptr,
                            uint16_t deviceIndex = 0) noexcept {
    using namespace audioapp;
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = normalizedToAmpDecaySec(params.snareDecay) + 0.05f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
        int activeNoteIndex = -1;
        int activePitch = 38;
        float activeVelocity = 100.0f;
        double activeElapsed = 0.0;

        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            bool inRelease = false;
            if (!isSnareNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
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
            triggerSnareVoice(runtime.voice, activePitch, activeVelocity);
            configureSnareVoice(runtime.voice, params, static_cast<float>(sampleRate));
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.snareVelocity * (1.0f - vel);
        float panelGain = perFramePanelGain != nullptr ? perFramePanelGain[frame] : 1.0f;
        if (instMod != nullptr && activeNoteIndex >= 0) {
            const auto& note = notes[activeNoteIndex];
            const NoteModKey key = noteModKeyFromRegion(
                note.pitch, note.clipStartBeat, note.noteStartBeat);
            const ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
            panelGain = applyPerNoteCommonGain(panelGain,
                                               deviceIndex,
                                               activeElapsed,
                                               key,
                                               evalCtx,
                                               *instMod);
        }
        monoOut[frame] += snareGeneratorSample(runtime.voice, params, sampleRate, velGain) * panelGain;
    }
}

} // namespace

namespace audioapp {

void SnareProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!ctx.suppressInstruments && ctx.noteCount > 0) {
        const auto& sp = std::get<SnareGeneratorParams>(*ctx.modulatedParams);
        const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
        for (int i = 0; i < regionCount; ++i) {
            const MidiPlaybackNote& note = ctx.notes[i];
            ctx.scratch.snareRegions[i] = SnareMidiNoteRegion{
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
        mixSnareMidiNotesBlock(
            ctx.scratch.scratch,
            block.numSamples,
            ctx.sampleRate,
            ctx.bpm,
            ctx.playheadBeat,
            ctx.scratch.snareRegions,
            regionCount,
            sp,
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