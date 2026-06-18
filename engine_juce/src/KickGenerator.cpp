#include "audioapp/KickGenerator.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/MidiUtils.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr double kTwoPi = 6.28318530718;

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

float kickNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

bool isKickNoteAudible(const KickMidiNoteRegion& note,
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
    return 0.08f + (1.0f - clamped) * 0.42f;
}

} // namespace

void triggerKickVoice(KickVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseSeed = 0.1f + static_cast<float>(pitch) * 0.013f;
}

float kickGeneratorSample(KickVoiceRuntime& voice,
                          const KickGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float pitchNorm = std::clamp(params.kickPitch, 0.0f, 1.0f);
    const float punchNorm = std::clamp(params.kickPunch, 0.0f, 1.0f);
    const float clickNorm = std::clamp(params.kickClick, 0.0f, 1.0f);
    const float toneNorm = std::clamp(params.kickTone, 0.0f, 1.0f);

    const float startHz = 80.0f + pitchNorm * 120.0f;
    const float endHz = 35.0f + (1.0f - punchNorm) * 25.0f;
    const float pitchDecaySec = 0.04f + (1.0f - punchNorm) * 0.12f;
    const float ampDecaySec = normalizedToAmpDecaySec(params.kickDecay);

    const float tuneRatio =
        std::pow(2.0f, static_cast<float>(voice.pitch - 36) / 12.0f);
    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float currentHz =
        (endHz + (startHz - endHz) * static_cast<float>(std::exp(-t / pitchDecaySec))) *
        tuneRatio;
    voice.phase += static_cast<float>(kTwoPi * currentHz / sampleRate);
    if (voice.phase >= static_cast<float>(kTwoPi)) {
        voice.phase -= static_cast<float>(kTwoPi);
    }

    const float drive = 1.0f + toneNorm * 3.0f;
    float body = std::sin(voice.phase);
    body = std::tanh(body * drive);

    float click = 0.0f;
    if (clickNorm > 0.001f && t < 0.004) {
        click = kickNoiseSample(voice.noiseSeed) *
                static_cast<float>(std::exp(-t / 0.0015)) * clickNorm;
    }

    const float sample = (body * (1.0f - clickNorm * 0.35f) + click) * ampEnv * velocityGain;
    return sample * params.gain * kInstrumentOutputGain;
}

void mixKickMidiNotesBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const KickMidiNoteRegion* notes,
                           int noteCount,
                           const KickGeneratorParams& params,
                           KickGeneratorRuntime& runtime) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = normalizedToAmpDecaySec(params.kickDecay) + 0.05f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
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
        monoOut[frame] += kickGeneratorSample(runtime.voice, params, sampleRate, velGain);
    }
}

} // namespace audioapp
