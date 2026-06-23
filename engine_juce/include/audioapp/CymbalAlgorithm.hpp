#pragma once

#include "audioapp/MetallicNoiseSynth.hpp"

#include <cstdint>

namespace audioapp {

struct CymbalGeneratorParams {
    float gain = 1.0f;
    float cymbalModel = 0.0f;
    float cymbalColor = 0.68f;      // spectral tilt: 0=dark/warm, 1=bright/icy
    float cymbalDecay = 0.50f;      // 0=short (closed hat), 1=long (open hat)
    float cymbalWidth = 0.35f;      // stereo width (0=mono, 1=max)
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

/// Returns left sample; caller calls sampleR for right channel.
float cymbalGeneratorSampleL(CymbalVoiceRuntime& voice,
                             const CymbalGeneratorParams& params,
                             double sampleRate,
                             float velocityGain) noexcept;

float cymbalGeneratorSampleR(CymbalVoiceRuntime& voice,
                             const CymbalGeneratorParams& params,
                             double sampleRate,
                             float velocityGain) noexcept;

} // namespace audioapp