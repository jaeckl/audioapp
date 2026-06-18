#pragma once

#include <cstdint>

namespace audioapp {

static constexpr int kCymbalPartialCount = 8;

struct CymbalGeneratorParams {
    float gain = 1.0f;
    float cymbalMetal = 0.55f;
    float cymbalBrightness = 0.60f;
    float cymbalDecay = 0.50f;
    float cymbalChoke = 0.0f;
    float cymbalVelocity = 1.0f;
};

struct CymbalVoiceRuntime {
    uint8_t active = 0;
    int pitch = 42;
    float velocity = 100.0f;
    double elapsedSec = 0.0;
    float partialPhases[kCymbalPartialCount] = {};
    float noiseSeed = 0.321f;
};

struct CymbalGeneratorRuntime {
    CymbalVoiceRuntime voice{};
    int lastNoteKey = -1;
};

struct CymbalMidiNoteRegion {
    int pitch = 42;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

void triggerCymbalVoice(CymbalVoiceRuntime& voice, int pitch, float velocity) noexcept;

float cymbalGeneratorSample(CymbalVoiceRuntime& voice,
                            const CymbalGeneratorParams& params,
                            double sampleRate,
                            float velocityGain) noexcept;

void mixCymbalMidiNotesBlock(float* monoOut,
                             int numFrames,
                             double sampleRate,
                             int bpm,
                             double playheadStartBeat,
                             const CymbalMidiNoteRegion* notes,
                             int noteCount,
                             const CymbalGeneratorParams& params,
                             CymbalGeneratorRuntime& runtime) noexcept;

} // namespace audioapp
