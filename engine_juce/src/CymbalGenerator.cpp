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

float cymbalNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

bool isCymbalNoteAudible(const CymbalMidiNoteRegion& note,
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
    return 0.4f + (1.0f - clamped) * 2.6f;
}

} // namespace

void triggerCymbalVoice(CymbalVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseSeed = 0.15f + static_cast<float>(pitch) * 0.009f;
}

float cymbalGeneratorSample(CymbalVoiceRuntime& voice,
                            const CymbalGeneratorParams& params,
                            double sampleRate,
                            float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float metalNorm = std::clamp(params.cymbalMetal, 0.0f, 1.0f);
    const float brightNorm = std::clamp(params.cymbalBrightness, 0.0f, 1.0f);
    const float chokeNorm = std::clamp(params.cymbalChoke, 0.0f, 1.0f);

    float ampDecaySec = normalizedToAmpDecaySec(params.cymbalDecay);
    ampDecaySec *= 1.0f - chokeNorm * 0.45f;

    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float tuneRatio =
        std::pow(2.0f, static_cast<float>(voice.pitch - 42) / 12.0f);
    const float baseHz = (280.0f + metalNorm * 420.0f) * tuneRatio;

    float sample = 0.0f;
    for (int i = 0; i < kCymbalPartialCount; ++i) {
        const float ratio = 1.15f + static_cast<float>(i) * (0.41f + metalNorm * 0.28f);
        const float hz = baseHz * ratio;
        const float partialDecay = ampDecaySec * (0.35f + static_cast<float>(i) * 0.09f);
        const float partialEnv =
            static_cast<float>(std::exp(-t / static_cast<double>(partialDecay)));
        voice.partialPhases[i] += static_cast<float>(kTwoPi * hz / sampleRate);
        if (voice.partialPhases[i] >= static_cast<float>(kTwoPi)) {
            voice.partialPhases[i] -= static_cast<float>(kTwoPi);
        }
        const float weight = 1.0f / static_cast<float>(i + 1);
        sample += std::sin(voice.partialPhases[i]) * partialEnv * weight;
    }

    const float noiseEnv = static_cast<float>(std::exp(-t / (ampDecaySec * 0.35)));
    const float noise = cymbalNoiseSample(voice.noiseSeed) * noiseEnv * brightNorm * 0.35f;
    sample = (sample * (0.55f + metalNorm * 0.35f) + noise) * ampEnv * velocityGain;

    return sample * params.gain * kInstrumentOutputGain;
}

void mixCymbalMidiNotesBlock(float* monoOut,
                             int numFrames,
                             double sampleRate,
                             int bpm,
                             double playheadStartBeat,
                             const CymbalMidiNoteRegion* notes,
                             int noteCount,
                             const CymbalGeneratorParams& params,
                             CymbalGeneratorRuntime& runtime) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = normalizedToAmpDecaySec(params.cymbalDecay) + 0.1f;

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
            if (!isCymbalNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds, inRelease)) {
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
            triggerCymbalVoice(runtime.voice, activePitch, activeVelocity);
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.cymbalVelocity * (1.0f - vel);
        monoOut[frame] += cymbalGeneratorSample(runtime.voice, params, sampleRate, velGain);
    }
}

} // namespace audioapp
