#pragma once

#include <cstdint>

namespace audioapp {

struct SnareGeneratorParams {
    float gain = 1.0f;
    float snareBody = 0.55f;
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
    float bodyPhase = 0.0f;
    double elapsedSec = 0.0;
    float noiseSeed = 0.456f;
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

void triggerSnareVoice(SnareVoiceRuntime& voice, int pitch, float velocity) noexcept;

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
