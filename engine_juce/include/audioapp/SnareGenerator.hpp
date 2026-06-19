#pragma once

#include "audioapp/SamplerFilter.hpp"

#include <cstdint>

namespace audioapp {

struct SnareGeneratorParams {
    float gain = 1.0f;
    float snareModel = 0.0f;
    float snareBody = 0.45f;
    float snareRing = 0.40f;
    float snareTune = 0.50f;
    float snareSnares = 0.60f;
    float snareSnap = 0.40f;
    float snareDecay = 0.50f;
    float snareVelocity = 1.0f;
};

struct SnareVoiceRuntime {
    uint8_t active = 0;
    int pitch = 38;
    float velocity = 100.0f;
    double elapsedSec = 0.0;
    uint32_t noiseState = 0xC8013EA4u;
    float bodyPhase = 0.0f;
    float ringPhase = 0.0f;
    float bodyStartHz = 300.0f;
    float bodyEndHz = 170.0f;
    float bodyPitchTau = 0.02f;
    float bodyDecaySec = 0.06f;
    float ringHz = 220.0f;
    float ringDecaySec = 0.12f;
    float wiresDecaySec = 0.2f;
    BiquadCoeffs wiresCoeffs{};
    BiquadCoeffs snapCoeffs{};
    BiquadCoeffs ringCoeffs{};
    BiquadState wiresState{};
    BiquadState snapState{};
    BiquadState ringState{};
};

struct SnareGeneratorRuntime {
    SnareVoiceRuntime voice{};
    int lastNoteKey = -1;
};

struct SnareMidiNoteRegion {
    int pitch = 38;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

int snareModelIndex(float snareModel) noexcept;

void triggerSnareVoice(SnareVoiceRuntime& voice, int pitch, float velocity) noexcept;

void configureSnareVoice(SnareVoiceRuntime& voice,
                         const SnareGeneratorParams& params,
                         float sampleRate) noexcept;

float snareGeneratorSample(SnareVoiceRuntime& voice,
                           const SnareGeneratorParams& params,
                           double sampleRate,
                           float velocityGain) noexcept;

void mixSnareMidiNotesBlock(float* monoOut,
                            int numFrames,
                            double sampleRate,
                            int bpm,
                            double playheadStartBeat,
                            const SnareMidiNoteRegion* notes,
                            int noteCount,
                            const SnareGeneratorParams& params,
                            SnareGeneratorRuntime& runtime) noexcept;

} // namespace audioapp
