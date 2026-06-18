#pragma once

#include <cstdint>

namespace audioapp {

struct ClapGeneratorParams {
    float gain = 1.0f;
    float clapBursts = 0.50f;
    float clapSpread = 0.45f;
    float clapTone = 0.55f;
    float clapRoom = 0.50f;
    float clapDecay = 0.50f;
};

struct ClapVoiceRuntime {
    uint8_t active = 0;
    float velocity = 100.0f;
    double elapsedSec = 0.0;
    float noiseSeed = 0.789f;
    int burstCount = 3;
    float burstOffsets[5] = {};
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
};

void triggerClapVoice(ClapVoiceRuntime& voice,
                      float velocity,
                      const ClapGeneratorParams& params) noexcept;

float clapGeneratorSample(ClapVoiceRuntime& voice,
                          const ClapGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept;

void mixClapMidiNotesBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const ClapMidiNoteRegion* notes,
                           int noteCount,
                           const ClapGeneratorParams& params,
                           ClapGeneratorRuntime& runtime) noexcept;

} // namespace audioapp
