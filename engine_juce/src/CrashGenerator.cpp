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

/// Crash: 0 = ~0.5s, 1 = ~4s
float crashDecaySeconds(float decayNorm) noexcept {
    return 0.45f + std::clamp(decayNorm, 0.0f, 1.0f) * 3.0f;
}

MetallicNoiseTimbre crashTimbre(float colorNorm, float spreadNorm, float decayNorm,
                                 int modelIndex) noexcept {
    MetallicNoiseTimbre t{};
    const float color = std::clamp(colorNorm, 0.0f, 1.0f);

    switch (modelIndex) {
    case 1: // Classic
        t.decaySec = 0.6f + decayNorm * 3.5f;
        t.lpSweepTau = 0.42f;
        t.thwackDecaySec = 0.018f;
        break;
    case 2: // Dark
        t.decaySec = 0.7f + decayNorm * 4.0f;
        t.lpSweepTau = 0.52f;
        t.thwackDecaySec = 0.020f;
        break;
    case 0:
    default: // Bright
        t.decaySec = 0.5f + decayNorm * 3.0f;
        t.lpSweepTau = 0.36f;
        t.thwackDecaySec = 0.018f;
        break;
    }

    t.bodyAmount = 0.05f * (1.0f - color);
    t.bodyHz = 320.0f;
    t.bodyQ = 1.0f;
    t.midWashHz = 1600.0f + color * 1400.0f;
    t.midWashQ = 0.58f;
    t.midWashAmount = 0.26f + color * 0.22f;
    t.resMinHz = 550.0f;
    t.resMaxHz = 15000.0f;
    t.resQ = 0.42f + color * 0.32f;
    t.resMix = 0.10f + color * 0.18f;
    t.resExciteRaw = 0.58f;
    t.lpSweepStartHz = 5500.0f + color * 12000.0f;
    t.lpSweepEndHz = 400.0f + color * 450.0f;
    t.hpShimmerHz = 3200.0f + color * 4800.0f;
    t.hpShimmerAmount = 0.14f + color * 0.32f;
    t.driverMix = 0.36f + color * 0.24f;
    t.crashNoiseMix = 0.10f + color * 0.18f;
    t.thwackAmount = 0.10f + color * 0.12f;

    t.widthAmount = std::clamp(spreadNorm, 0.0f, 1.0f);
    t.widthDetuneCents = 8.0f + spreadNorm * 14.0f;
    return t;
}

} // namespace

int crashModelIndex(float crashModel) noexcept {
    return std::clamp(static_cast<int>(std::lround(crashModel * 2.0f)), 0, 2);
}

void triggerCrashVoice(CrashVoiceRuntime& voice, int pitch, float velocity) noexcept {
    triggerMetallicNoiseVoice(voice, pitch, velocity);
}

float crashGeneratorSampleL(CrashVoiceRuntime& voice,
                             const CrashGeneratorParams& params,
                             double sampleRate,
                             float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float colorNorm = std::clamp(params.crashColor, 0.0f, 1.0f);
    const float spreadNorm = std::clamp(params.crashSpread, 0.0f, 1.0f);
    const float decayNorm = std::clamp(params.crashDecay, 0.0f, 1.0f);
    const int modelIdx = crashModelIndex(params.crashModel);

    auto timbre = crashTimbre(colorNorm, spreadNorm, decayNorm, modelIdx);

    updateResonatorBank(voice, timbre, colorNorm, spreadNorm, static_cast<float>(sampleRate));

    return metallicNoiseSampleL(voice, timbre, sampleRate, velocityGain,
                                params.gain * kInstrumentOutputGain);
}

float crashGeneratorSampleR(CrashVoiceRuntime& voice,
                             const CrashGeneratorParams& params,
                             double sampleRate,
                             float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float colorNorm = std::clamp(params.crashColor, 0.0f, 1.0f);
    const float spreadNorm = std::clamp(params.crashSpread, 0.0f, 1.0f);
    const float decayNorm = std::clamp(params.crashDecay, 0.0f, 1.0f);
    const int modelIdx = crashModelIndex(params.crashModel);

    auto timbre = crashTimbre(colorNorm, spreadNorm, decayNorm, modelIdx);

    updateResonatorBank(voice, timbre, colorNorm, spreadNorm, static_cast<float>(sampleRate));

    return metallicNoiseSampleR(voice, timbre, sampleRate, velocityGain,
                                params.gain * kInstrumentOutputGain);
}

void mixCrashMidiNotesBlockStereo(float* trackLeftOut,
                                   float* trackRightOut,
                                   int numFrames,
                                   double sampleRate,
                                   int bpm,
                                   double playheadStartBeat,
                                   const CrashMidiNoteRegion* notes,
                                   int noteCount,
                                   const CrashGeneratorParams& params,
                                   CrashGeneratorRuntime& runtime,
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
            crashGeneratorSampleL(runtime.voice, params, sampleRate, velGain) * gain;
        trackRightOut[frame] +=
            crashGeneratorSampleR(runtime.voice, params, sampleRate, velGain) * gain;
    }
}

} // namespace audioapp