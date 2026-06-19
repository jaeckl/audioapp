#include "audioapp/CymbalGenerator.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr double kTwoPi = 6.28318530718;

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

float isCymbalNoteAudible(const CymbalMidiNoteRegion& note,
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

/// Map 0..1 decay to seconds: 0 = short (closed hat ~80ms), 1 = long (open hat ~1.2s)
float cymbalDecaySeconds(float decayNorm) noexcept {
    return 0.035f + std::clamp(decayNorm, 0.0f, 1.0f) * 0.70f;
}

MetallicNoiseTimbre cymbalTimbre(float colorNorm, float decayNorm, float widthNorm,
                                  int modelIndex) noexcept {
    MetallicNoiseTimbre t{};
    const float color = std::clamp(colorNorm, 0.0f, 1.0f);

    switch (modelIndex) {
    case 1: // Open
        t.decaySec = 0.12f + decayNorm * 1.1f;
        t.lpSweepTau = 0.20f;
        t.thwackAmount = 0.05f + color * 0.05f;
        t.thwackDecaySec = 0.016f;
        break;
    case 2: // Pedal
        t.decaySec = 0.04f + decayNorm * 0.35f;
        t.lpSweepTau = 0.12f;
        t.thwackAmount = 0.06f + color * 0.05f;
        t.thwackDecaySec = 0.014f;
        break;
    case 0:
    default: // Closed
        t.decaySec = 0.035f + decayNorm * 0.70f;
        t.lpSweepTau = 0.14f + color * 0.08f;
        t.thwackAmount = 0.05f + color * 0.05f;
        t.thwackDecaySec = 0.015f;
        break;
    }

    t.lpSweepStartHz = 7000.0f + color * 14000.0f;
    t.lpSweepEndHz = 900.0f + color * 1400.0f;
    t.hpShimmerHz = 5500.0f + color * 7500.0f;
    t.hpShimmerAmount = 0.28f + color * 0.34f;
    t.bodyHz = 420.0f + color * 180.0f;
    t.bodyQ = 1.1f;
    t.bodyAmount = 0.08f + (1.0f - color) * 0.08f;
    t.midWashHz = 2000.0f + color * 2200.0f;
    t.midWashQ = 0.62f;
    t.midWashAmount = 0.20f + color * 0.18f;
    t.resMinHz = 500.0f;
    t.resMaxHz = 18000.0f;
    t.resQ = 0.48f + color * 0.38f;
    t.resMix = 0.20f + color * 0.26f;
    t.resExciteRaw = 0.52f;
    t.driverMix = 0.30f + color * 0.18f;

    t.widthAmount = std::clamp(widthNorm, 0.0f, 1.0f);
    t.widthDetuneCents = 6.0f + widthNorm * 10.0f;
    return t;
}

} // namespace

int cymbalModelIndex(float cymbalModel) noexcept {
    return std::clamp(static_cast<int>(std::lround(cymbalModel * 2.0f)), 0, 2);
}

void triggerCymbalVoice(CymbalVoiceRuntime& voice, int pitch, float velocity) noexcept {
    triggerMetallicNoiseVoice(voice, pitch, velocity);
}

float cymbalGeneratorSampleL(CymbalVoiceRuntime& voice,
                              const CymbalGeneratorParams& params,
                              double sampleRate,
                              float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float colorNorm = std::clamp(params.cymbalColor, 0.0f, 1.0f);
    const float decayNorm = std::clamp(params.cymbalDecay, 0.0f, 1.0f);
    const float widthNorm = std::clamp(params.cymbalWidth, 0.0f, 1.0f);
    const int modelIdx = cymbalModelIndex(params.cymbalModel);

    auto timbre = cymbalTimbre(colorNorm, decayNorm, widthNorm, modelIdx);

    updateResonatorBank(voice, timbre, colorNorm, widthNorm, static_cast<float>(sampleRate));

    return metallicNoiseSampleL(voice, timbre, sampleRate, velocityGain,
                                params.gain * kInstrumentOutputGain);
}

float cymbalGeneratorSampleR(CymbalVoiceRuntime& voice,
                              const CymbalGeneratorParams& params,
                              double sampleRate,
                              float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float colorNorm = std::clamp(params.cymbalColor, 0.0f, 1.0f);
    const float decayNorm = std::clamp(params.cymbalDecay, 0.0f, 1.0f);
    const float widthNorm = std::clamp(params.cymbalWidth, 0.0f, 1.0f);
    const int modelIdx = cymbalModelIndex(params.cymbalModel);

    auto timbre = cymbalTimbre(colorNorm, decayNorm, widthNorm, modelIdx);

    updateResonatorBank(voice, timbre, colorNorm, widthNorm, static_cast<float>(sampleRate));

    return metallicNoiseSampleR(voice, timbre, sampleRate, velocityGain,
                                params.gain * kInstrumentOutputGain);
}

void mixCymbalMidiNotesBlockStereo(float* trackLeftOut,
                                    float* trackRightOut,
                                    int numFrames,
                                    double sampleRate,
                                    int bpm,
                                    double playheadStartBeat,
                                    const CymbalMidiNoteRegion* notes,
                                    int noteCount,
                                    const CymbalGeneratorParams& params,
                                    CymbalGeneratorRuntime& runtime,
                                    const float* perFrameGain) noexcept {
    if (trackLeftOut == nullptr || trackRightOut == nullptr ||
        numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = cymbalDecaySeconds(params.cymbalDecay) + 0.08f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
        int activePitch = 42;
        float activeVelocity = 100.0f;
        double activeElapsed = 0.0;

        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            bool inRelease = false;
            if (isCymbalNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
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
            triggerCymbalVoice(runtime.voice, activePitch, activeVelocity);
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.cymbalVelocity * (1.0f - vel);
        const float gain = perFrameGain != nullptr ? perFrameGain[frame] : 1.0f;

        trackLeftOut[frame] +=
            cymbalGeneratorSampleL(runtime.voice, params, sampleRate, velGain) * gain;
        trackRightOut[frame] +=
            cymbalGeneratorSampleR(runtime.voice, params, sampleRate, velGain) * gain;
    }
}

} // namespace audioapp