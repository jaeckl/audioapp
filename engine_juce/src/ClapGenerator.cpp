#include "audioapp/ClapGenerator.hpp"

#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

float clapNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

bool isClapNoteAudible(const ClapMidiNoteRegion& note,
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
    return 0.12f + (1.0f - clamped) * 0.38f;
}

} // namespace

void triggerClapVoice(ClapVoiceRuntime& voice,
                      float velocity,
                      const ClapGeneratorParams& params) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.velocity = velocity;
    voice.noiseSeed = 0.33f;

    const float spreadNorm = std::clamp(params.clapSpread, 0.0f, 1.0f);
    const float burstsNorm = std::clamp(params.clapBursts, 0.0f, 1.0f);
    voice.burstCount = 2 + static_cast<int>(std::lround(burstsNorm * 3.0f));
    const float interval = 0.008f + (1.0f - spreadNorm) * 0.010f;

    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const float jitter =
            (clapNoiseSample(voice.noiseSeed) * 0.5f + 0.5f) * spreadNorm * 0.004f;
        voice.burstOffsets[i] = static_cast<float>(i) * interval + jitter;
    }
}

float clapGeneratorSample(ClapVoiceRuntime& voice,
                          const ClapGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float toneNorm = std::clamp(params.clapTone, 0.0f, 1.0f);
    const float roomNorm = std::clamp(params.clapRoom, 0.0f, 1.0f);
    const float ampDecaySec =
        normalizedToAmpDecaySec(params.clapDecay) * (0.7f + roomNorm * 0.8f);

    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    const float burstDecaySec = 0.04f + roomNorm * 0.14f;
    const float bpCenter = 800.0f + toneNorm * 3200.0f;
    float sample = 0.0f;

    for (int i = 0; i < voice.burstCount && i < 5; ++i) {
        const double localT = t - static_cast<double>(voice.burstOffsets[i]);
        if (localT < 0.0 || localT > 0.25) {
            continue;
        }
        const float env = static_cast<float>(std::exp(-localT / burstDecaySec));
        const float noise = clapNoiseSample(voice.noiseSeed);
        const float ring =
            noise * std::sin(static_cast<float>(2.0 * 3.14159265358979323846 * bpCenter * localT));
        sample += ring * env * (0.55f + toneNorm * 0.35f);
    }

    return sample * ampEnv * velocityGain * params.gain * kInstrumentOutputGain;
}

void mixClapMidiNotesBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const ClapMidiNoteRegion* notes,
                           int noteCount,
                           const ClapGeneratorParams& params,
                           ClapGeneratorRuntime& runtime) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float releaseSec = normalizedToAmpDecaySec(params.clapDecay) + 0.08f;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);

        int activeNoteKey = -1;
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
        monoOut[frame] += clapGeneratorSample(runtime.voice, params, sampleRate, velGain);
    }
}

} // namespace audioapp
