#pragma once

#include "audioapp/MetallicNoiseSynth.hpp"

#include <cstdint>

namespace audioapp {

struct CymbalGeneratorParams {
    float gain = 1.0f;
    float cymbalModel = 0.0f;
    float cymbalMetal = 0.55f;
    float cymbalBrightness = 0.60f;
    float cymbalDecay = 0.50f;
    float cymbalChoke = 0.0f;
    float cymbalVelocity = 1.0f;
};

struct CymbalVoiceRuntime : MetallicNoiseVoiceRuntime {};

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

int cymbalModelIndex(float cymbalModel) noexcept;

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
