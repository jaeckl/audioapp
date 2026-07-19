#pragma once

#include "audioapp/SamplerFilter.hpp"

#include <cstdint>

namespace audioapp {

struct ClapGeneratorParams {
    float gain = 1.0f;
    float clapBursts = 0.50f;
    float clapSpread = 0.45f;
    float clapTone = 0.55f;
    float clapRoom = 0.50f;
    float clapDecay = 0.50f;
    float clapVelocity = 1.0f;
    float clapPitch = 0.50f;
    float clapKeyTrack = 1.0f;
};

struct ClapVoiceRuntime {
    uint8_t active = 0;
    int pitch = 39;
    float velocity = 100.0f;
    double elapsedSec = 0.0;
    float noiseSeed = 0.789f;
    int burstCount = 3;
    float burstOffsets[5] = {};
    BiquadCoeffs palmCoeffs{};
    BiquadCoeffs airCoeffs{};
    BiquadState palmState{};
    BiquadState airState{};
    float configuredTone = -1.0f;
    float configuredPitchRatio = -1.0f;
    float configuredSampleRate = 0.0f;
};

struct ClapGeneratorRuntime {
    ClapVoiceRuntime voice{};
    int lastNoteKey = -1;
};

struct ClapMidiNoteRegion {
    int pitch = 39;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
    bool loopContent = false;
    double contentLengthBeats = 4.0;
};

void triggerClapVoice(ClapVoiceRuntime& voice,
                      int pitch,
                      float velocity,
                      const ClapGeneratorParams& params) noexcept;

float clapGeneratorSample(ClapVoiceRuntime& voice,
                          const ClapGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept;

} // namespace audioapp
