#include "audioapp/CrashGenerator.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

bool isCrashNoteAudible(const CrashMidiNoteRegion& note,
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

float normalizedToAmpDecaySec(float normalized, float minSec, float maxSec) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return minSec + (1.0f - clamped) * (maxSec - minSec);
}

MetallicNoiseTimbre crashTimbreForModel(int modelIndex,
                                        const CrashGeneratorParams& params) noexcept {
    MetallicNoiseTimbre timbre;
    timbre.metalNorm = params.crashWash;
    timbre.brightNorm = params.crashBright;
    timbre.decayNorm = params.crashDecay;
    timbre.chokeNorm = 0.0f;

    const float spread = std::clamp(params.crashSpread, 0.0f, 1.0f);

    switch (modelIndex) {
    case 1: // Classic
        timbre.minDecaySec = 0.55f;
        timbre.maxDecaySec = 2.4f;
        timbre.hpStartHz = 5200.0f + spread * 2200.0f;
        timbre.hpEndHz = 500.0f;
        timbre.sweepTauSec = 0.12f;
        timbre.washGain = 1.05f;
        timbre.attackGain = 0.72f;
        break;
    case 2: // Dark
        timbre.minDecaySec = 0.75f;
        timbre.maxDecaySec = 3.0f;
        timbre.hpStartHz = 3200.0f + spread * 1200.0f;
        timbre.hpEndHz = 320.0f;
        timbre.sweepTauSec = 0.18f;
        timbre.washGain = 0.92f;
        timbre.attackGain = 0.55f;
        break;
    case 0:
    default: // Bright
        timbre.minDecaySec = 0.45f;
        timbre.maxDecaySec = 2.0f;
        timbre.hpStartHz = 7600.0f + spread * 2800.0f;
        timbre.hpEndHz = 900.0f;
        timbre.sweepTauSec = 0.08f;
        timbre.washGain = 1.15f;
        timbre.attackGain = 0.85f;
        break;
    }
    return timbre;
}

} // namespace

int crashModelIndex(float crashModel) noexcept {
    return std::clamp(static_cast<int>(std::lround(crashModel * 2.0f)), 0, 2);
}

void triggerCrashVoice(CrashVoiceRuntime& voice, int pitch, float velocity) noexcept {
    triggerMetallicNoiseVoice(voice, pitch, velocity);
}

float crashGeneratorSample(CrashVoiceRuntime& voice,
                           const CrashGeneratorParams& params,
                           double sampleRate,
                           float velocityGain) noexcept {
    const auto timbre = crashTimbreForModel(crashModelIndex(params.crashModel), params);
    return metallicNoiseSample(voice, timbre, sampleRate, velocityGain,
                               params.gain * kInstrumentOutputGain);
}

void mixCrashMidiNotesBlock(float* monoOut,
                            int numFrames,
                            double sampleRate,
                            int bpm,
                            double playheadStartBeat,
                            const CrashMidiNoteRegion* notes,
                            int noteCount,
                            const CrashGeneratorParams& params,
                            CrashGeneratorRuntime& runtime) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec =
        normalizedToAmpDecaySec(params.crashDecay, 0.45f, 3.0f) + 0.15f;

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
            if (!isCrashNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
                continue;
            }
            activeNoteKey = note.noteKey;
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
            triggerCrashVoice(runtime.voice, activePitch, activeVelocity);
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.crashVelocity * (1.0f - vel);
        monoOut[frame] += crashGeneratorSample(runtime.voice, params, sampleRate, velGain);
    }
}

} // namespace audioapp
