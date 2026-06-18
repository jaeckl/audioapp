#pragma once

#include "audioapp/MetallicNoiseSynth.hpp"

#include <cstdint>

namespace audioapp {

struct CrashGeneratorParams {
    float gain = 1.0f;
    float crashModel = 0.0f;
    float crashWash = 0.60f;
    float crashBright = 0.65f;
    float crashSpread = 0.50f;
    float crashDecay = 0.55f;
    float crashVelocity = 1.0f;
};

struct CrashVoiceRuntime : MetallicNoiseVoiceRuntime {};

struct CrashGeneratorRuntime {
    CrashVoiceRuntime voice{};
    int lastNoteKey = -1;
};

struct CrashMidiNoteRegion {
    int pitch = 49;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

int crashModelIndex(float crashModel) noexcept;

void triggerCrashVoice(CrashVoiceRuntime& voice, int pitch, float velocity) noexcept;

float crashGeneratorSample(CrashVoiceRuntime& voice,
                           const CrashGeneratorParams& params,
                           double sampleRate,
                           float velocityGain) noexcept;

void mixCrashMidiNotesBlock(float* monoOut,
                            int numFrames,
                            double sampleRate,
                            int bpm,
                            double playheadStartBeat,
                            const CrashMidiNoteRegion* notes,
                            int noteCount,
                            const CrashGeneratorParams& params,
                            CrashGeneratorRuntime& runtime) noexcept;

} // namespace audioapp
