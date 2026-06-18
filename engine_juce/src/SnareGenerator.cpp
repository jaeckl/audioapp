#include "audioapp/SnareGenerator.hpp"

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

float snareNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

bool isSnareNoteAudible(const SnareMidiNoteRegion& note,
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

float normalizedToAmpDecaySec(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 0.15f + (1.0f - clamped) * 0.35f;
}

} // namespace

void triggerSnareVoice(SnareVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseSeed = 0.2f + static_cast<float>(pitch) * 0.011f;
}

float snareGeneratorSample(SnareVoiceRuntime& voice,
                           const SnareGeneratorParams& params,
                           double sampleRate,
                           float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float bodyNorm = std::clamp(params.snareBody, 0.0f, 1.0f);
    const float tuneNorm = std::clamp(params.snareTune, 0.0f, 1.0f);
    const float snaresNorm = std::clamp(params.snareSnares, 0.0f, 1.0f);
    const float snapNorm = std::clamp(params.snareSnap, 0.0f, 1.0f);

    const float ampDecaySec = normalizedToAmpDecaySec(params.snareDecay);
    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float tuneRatio =
        std::pow(2.0f, static_cast<float>(voice.pitch - 38) / 12.0f);
    const float bodyHz = (120.0f + tuneNorm * 160.0f) * tuneRatio;
    const float bodyDecaySec = 0.04f + (1.0f - bodyNorm) * 0.08f;
    const float bodyEnv = static_cast<float>(std::exp(-t / static_cast<double>(bodyDecaySec)));
    voice.bodyPhase += static_cast<float>(kTwoPi * bodyHz / sampleRate);
    if (voice.bodyPhase >= static_cast<float>(kTwoPi)) {
        voice.bodyPhase -= static_cast<float>(kTwoPi);
    }
    const float body = std::sin(voice.bodyPhase) * bodyEnv * (0.25f + bodyNorm * 0.55f);

    const float noiseDecaySec = 0.12f + (1.0f - snaresNorm) * 0.28f;
    const float noiseEnv = static_cast<float>(std::exp(-t / static_cast<double>(noiseDecaySec)));
    const float bpCenter = 600.0f + tuneNorm * 2400.0f;
    const float rawNoise = snareNoiseSample(voice.noiseSeed);
    const float ringMod =
        std::sin(static_cast<float>(kTwoPi * bpCenter * t)) * rawNoise * noiseEnv;
    const float snares = ringMod * (0.2f + snaresNorm * 0.65f);

    float snap = 0.0f;
    if (snapNorm > 0.001f && t < 0.006) {
        snap = rawNoise * static_cast<float>(std::exp(-t / 0.0018)) * snapNorm * 0.85f;
    }

    const float sample = (body + snares + snap) * ampEnv * velocityGain;
    return sample * params.gain * kInstrumentOutputGain;
}

void mixSnareMidiNotesBlock(float* monoOut,
                            int numFrames,
                            double sampleRate,
                            int bpm,
                            double playheadStartBeat,
                            const SnareMidiNoteRegion* notes,
                            int noteCount,
                            const SnareGeneratorParams& params,
                            SnareGeneratorRuntime& runtime) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = normalizedToAmpDecaySec(params.snareDecay) + 0.05f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
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
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.snareVelocity * (1.0f - vel);
        monoOut[frame] += snareGeneratorSample(runtime.voice, params, sampleRate, velGain);
    }
}

} // namespace audioapp
