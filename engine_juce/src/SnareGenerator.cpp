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

float xorshiftNoise(uint32_t& state) noexcept {
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    return static_cast<float>(state) * (1.0f / 2147483648.0f) - 1.0f;
}

uint32_t seedFromPitch(int pitch) noexcept {
    return 0x9E3779B9u ^ static_cast<uint32_t>(pitch) * 0x85EBCA6Bu;
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

float pitchTrackRatio(int pitch) noexcept {
    return std::pow(2.0f, static_cast<float>(pitch - 38) / 12.0f);
}

} // namespace

int snareModelIndex(float snareModel) noexcept {
    return std::clamp(static_cast<int>(std::lround(snareModel * 2.0f)), 0, 2);
}

void configureSnareVoice(SnareVoiceRuntime& voice,
                         const SnareGeneratorParams& params,
                         float sampleRate) noexcept {
    if (sampleRate <= 0.0f) {
        return;
    }

    const float bodyNorm = std::clamp(params.snareBody, 0.0f, 1.0f);
    const float ringNorm = std::clamp(params.snareRing, 0.0f, 1.0f);
    const float tuneNorm = std::clamp(params.snareTune, 0.0f, 1.0f);
    const float snaresNorm = std::clamp(params.snareSnares, 0.0f, 1.0f);
    const float snapNorm = std::clamp(params.snareSnap, 0.0f, 1.0f);
    const float tuneRatio = pitchTrackRatio(voice.pitch);

    switch (snareModelIndex(params.snareModel)) {
    case 1: // Tight (stub)
    case 2: // 909 (stub)
    case 0:
    default:
        voice.bodyStartHz = (270.0f + tuneNorm * 70.0f) * tuneRatio;
        voice.bodyEndHz = voice.bodyStartHz * (0.46f + (1.0f - bodyNorm) * 0.14f);
        voice.bodyPitchTau = 0.015f + bodyNorm * 0.013f;
        voice.bodyDecaySec = 0.032f + bodyNorm * 0.045f;
        voice.wiresDecaySec = 0.085f + snaresNorm * 0.265f;
        voice.ringHz =
            std::clamp((150.0f + tuneNorm * 170.0f) * tuneRatio, 80.0f, sampleRate * 0.42f);
        voice.ringDecaySec = 0.048f + ringNorm * 0.17f;
        break;
    }

    const float wireCenter =
        std::clamp((1900.0f + tuneNorm * 5100.0f) * std::min(tuneRatio, 1.35f),
                   400.0f,
                   sampleRate * 0.42f);
    const float wireQ = std::clamp(1.1f - snaresNorm * 0.62f, 0.45f, 1.4f);
    cookSamplerBiquad(voice.wiresCoeffs, 2, sampleRate, wireCenter, wireQ);

    const float ringQ = std::clamp(0.7f + ringNorm * 2.2f, 0.55f, 3.0f);
    cookSamplerBiquad(voice.ringCoeffs, 2, sampleRate, voice.ringHz, ringQ);

    const float snapHp =
        std::clamp(3600.0f + snapNorm * 4800.0f, 200.0f, sampleRate * 0.42f);
    cookSamplerBiquad(voice.snapCoeffs, 1, sampleRate, snapHp, 0.72f);
}

void triggerSnareVoice(SnareVoiceRuntime& voice, int pitch, float velocity) noexcept {
    std::memset(&voice, 0, sizeof(voice));
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.noiseState = seedFromPitch(pitch);
}

float snareGeneratorSample(SnareVoiceRuntime& voice,
                           const SnareGeneratorParams& params,
                           double sampleRate,
                           float velocityGain) noexcept {
    if (voice.active == 0 || sampleRate <= 0.0) {
        return 0.0f;
    }

    const float bodyNorm = std::clamp(params.snareBody, 0.0f, 1.0f);
    const float ringNorm = std::clamp(params.snareRing, 0.0f, 1.0f);
    const float snaresNorm = std::clamp(params.snareSnares, 0.0f, 1.0f);
    const float snapNorm = std::clamp(params.snareSnap, 0.0f, 1.0f);

    const float ampDecaySec = normalizedToAmpDecaySec(params.snareDecay);
    const double t = voice.elapsedSec;
    const float ampEnv = static_cast<float>(std::exp(-t / static_cast<double>(ampDecaySec)));
    if (ampEnv <= 0.00001f) {
        voice.active = 0;
        return 0.0f;
    }

    if (voice.bodyStartHz < 1.0f) {
        configureSnareVoice(voice, params, static_cast<float>(sampleRate));
    }

    const float bodyHz =
        voice.bodyEndHz +
        (voice.bodyStartHz - voice.bodyEndHz) *
            static_cast<float>(std::exp(-t / static_cast<double>(voice.bodyPitchTau)));
    voice.bodyPhase += static_cast<float>(kTwoPi * bodyHz / sampleRate);
    if (voice.bodyPhase >= static_cast<float>(kTwoPi)) {
        voice.bodyPhase -= static_cast<float>(kTwoPi);
    }

    const float bodyEnv =
        static_cast<float>(std::exp(-t / static_cast<double>(voice.bodyDecaySec)));
    const float bodyFund = std::sin(voice.bodyPhase);
    const float bodyHarm = std::sin(voice.bodyPhase * 2.0f);
    const float body =
        (bodyFund * 0.88f + bodyHarm * (0.06f + bodyNorm * 0.08f)) * bodyEnv *
        (0.08f + bodyNorm * 0.20f);

    const float ringEnv =
        static_cast<float>(std::exp(-t / static_cast<double>(voice.ringDecaySec)));
    voice.ringPhase += static_cast<float>(kTwoPi * voice.ringHz / sampleRate);
    if (voice.ringPhase >= static_cast<float>(kTwoPi)) {
        voice.ringPhase -= static_cast<float>(kTwoPi);
    }

    const float wiresEnv =
        static_cast<float>(std::exp(-t / static_cast<double>(voice.wiresDecaySec)));
    const float rawNoise = xorshiftNoise(voice.noiseState);
    const float wireNoise = processBiquadSample(rawNoise, voice.wiresCoeffs, voice.wiresState);
    const float ringNoise = processBiquadSample(rawNoise, voice.ringCoeffs, voice.ringState);
    const float ringTone = std::sin(voice.ringPhase) * (0.10f + ringNorm * 0.16f);
    const float ringAm =
        std::sin(static_cast<float>(kTwoPi * voice.ringHz * t)) * ringNoise *
        (0.12f + ringNorm * 0.30f);
    const float ring = (ringNoise * (0.50f + ringNorm * 0.28f) + ringTone + ringAm) * ringEnv *
                       (0.05f + ringNorm * 0.36f);
    const float wires = wireNoise * wiresEnv * (0.26f + snaresNorm * 0.52f);

    float snap = 0.0f;
    if (snapNorm > 0.001f && t < 0.012) {
        const float snapNoise = processBiquadSample(rawNoise, voice.snapCoeffs, voice.snapState);
        snap = snapNoise * static_cast<float>(std::exp(-t / 0.0022)) * snapNorm * 0.62f;
    }

    const float mixed = body + ring + wires + snap;
    const float driven = mixed / (1.0f + std::abs(mixed) * 0.35f);
    return driven * ampEnv * velocityGain * params.gain * kInstrumentOutputGain;
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
            configureSnareVoice(runtime.voice, params, static_cast<float>(sampleRate));
            runtime.lastNoteKey = activeNoteKey;
        }
        runtime.voice.elapsedSec = activeElapsed;

        const float vel = std::clamp(runtime.voice.velocity / 127.0f, 0.0f, 1.0f);
        const float velGain = 1.0f - params.snareVelocity * (1.0f - vel);
        monoOut[frame] += snareGeneratorSample(runtime.voice, params, sampleRate, velGain);
    }
}

} // namespace audioapp
