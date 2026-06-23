#include "audioapp/devices/processors/CrashProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cstring>
#include <algorithm>
#include <cmath>

namespace {

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

bool isCrashNoteAudible(const audioapp::CrashMidiNoteRegion& note,
                        double beat,
                        int bpm,
                        float releaseSec,
                        double& elapsedSecondsOut,
                        bool& inReleaseOut) noexcept {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats || bpm <= 0) {
        return false;
    }

    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
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

float crashDecaySeconds(float decayNorm) noexcept {
    return 0.45f + std::clamp(decayNorm, 0.0f, 1.0f) * 3.0f;
}

void mixCrashMidiNotesBlockStereo(float* trackLeftOut,
                                   float* trackRightOut,
                                   int numFrames,
                                   double sampleRate,
                                   int bpm,
                                   double playheadStartBeat,
                                   const audioapp::CrashMidiNoteRegion* notes,
                                   int noteCount,
                                   const audioapp::CrashGeneratorParams& params,
                                   audioapp::CrashGeneratorRuntime& runtime,
                                   const float* perFrameGain) noexcept {
    if (trackLeftOut == nullptr || trackRightOut == nullptr ||
        numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = crashDecaySeconds(params.crashDecay) + 0.15f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
        int activePitch = 49;
        float activeVelocity = 100.0f;
        double activeElapsed = 0.0;

        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            bool inRelease = false;
            if (isCrashNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
                activeNoteKey = note.noteKey;
                activePitch = note.pitch;
                activeVelocity = note.velocity;
                activeElapsed = elapsedSeconds;
            }
        }

        if (activeNoteKey < 0) {
            runtime.voice.active = 0;
            runtime.lastNoteKey = -1;
            continue;
        }

        if (runtime.lastNoteKey != activeNoteKey || runtime.voice.active == 0) {
            triggerCrashVoice(runtime.voice, activePitch, activeVelocity);
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.crashVelocity * (1.0f - vel);
        const float gain = perFrameGain != nullptr ? perFrameGain[frame] : 1.0f;

        trackLeftOut[frame] +=
            audioapp::crashGeneratorSampleL(runtime.voice, params, sampleRate, velGain) * gain;
        trackRightOut[frame] +=
            audioapp::crashGeneratorSampleR(runtime.voice, params, sampleRate, velGain) * gain;
    }
}

} // anonymous namespace

namespace audioapp {

void CrashProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (!ctx.suppressInstruments && ctx.noteCount > 0) {
        const auto& crp = std::get<CrashGeneratorParams>(*ctx.modulatedParams);
        const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
        for (int i = 0; i < regionCount; ++i) {
            const MidiPlaybackNote& note = ctx.notes[i];
            ctx.scratch.crashRegions[i] = CrashMidiNoteRegion{
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
        mixCrashMidiNotesBlockStereo(
            ctx.scratch.tempStereoL,
            ctx.scratch.tempStereoR,
            block.numSamples,
            ctx.sampleRate,
            ctx.bpm,
            ctx.playheadBeat,
            ctx.scratch.crashRegions,
            regionCount,
            crp,
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