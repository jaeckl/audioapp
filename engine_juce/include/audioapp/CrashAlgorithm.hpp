#pragma once

#include "audioapp/MetallicNoiseSynth.hpp"

#include <cstdint>

namespace audioapp {

struct CrashGeneratorParams {
    float gain = 1.0f;
    float crashModel = 0.0f;
    float crashColor = 0.62f;       // wash + brightness: 0=dark, 1=bright/explosive
    float crashSpread = 0.50f;     // stereo width
    float crashDecay = 0.55f;      // 0=short, 1=long
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

float crashGeneratorSampleL(CrashVoiceRuntime& voice,
                            const CrashGeneratorParams& params,
                            double sampleRate,
                            float velocityGain) noexcept;

float crashGeneratorSampleR(CrashVoiceRuntime& voice,
                            const CrashGeneratorParams& params,
                            double sampleRate,
                            float velocityGain) noexcept;

} // namespace audioapp