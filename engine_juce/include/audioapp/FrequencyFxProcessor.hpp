#pragma once

#include "audioapp/SamplerFilter.hpp"

namespace audioapp {

// --- Filter ---
struct FilterParams {
    float cutoffHz = 1000.0f;      // 20 – 20000 Hz
    float resonance = 0.707f;      // Q factor
    int filterMode = 0;            // 0=LP, 1=HP, 2=BP, 3=Notch
};

struct FilterRuntime {
    BiquadState left;
    BiquadState right;
};

// --- 4-Band EQ ---
struct FourBandEqBandParams {
    float frequencyHz = 1000.0f;
    float gainDb = 0.0f;
    float q = 0.707f;
};

struct FourBandEqParams {
    FourBandEqBandParams bands[4];  // 0=LowShelf, 1=LowMid(Peak), 2=HighMid(Peak), 3=HighShelf
};

struct FourBandEqRuntime {
    BiquadState bands[4][2];  // [band][channel]
};

// --- Frequency Shifter (ring modulator) ---
struct FrequencyShifterParams {
    float shiftHz = 0.0f;     // coarse + fine combined, -2050..+2050
    float mix = 1.0f;         // 0 dry .. 1 wet
    float tone = 1.0f;        // 0 dark LP .. 1 open
    float feedback = 0.0f;    // 0..~0.95 into ring input
};

struct FrequencyShifterRuntime {
    double phaseL = 0.0;
    double phaseR = 0.0;
    float feedbackL = 0.0f;
    float feedbackR = 0.0f;
    float toneL = 0.0f;
    float toneR = 0.0f;
};

// --- Processing function declarations ---
void processFilterStereoBlock(float* trackLeft,
                              float* trackRight,
                              int numFrames,
                              double sampleRate,
                              const FilterParams& params,
                              FilterRuntime& runtime) noexcept;

void processFourBandEqStereoBlock(float* trackLeft,
                                  float* trackRight,
                                  int numFrames,
                                  double sampleRate,
                                  const FourBandEqParams& params,
                                  FourBandEqRuntime& runtime) noexcept;

void processFrequencyShifterStereoBlock(float* trackLeft,
                                        float* trackRight,
                                        int numFrames,
                                        double sampleRate,
                                        const FrequencyShifterParams& params,
                                        FrequencyShifterRuntime& runtime) noexcept;

// --- Helpers (reused by all three) ---
float normalizedToFrequency(float normalized) noexcept;  // 0-1 → 20-20000 Hz (logarithmic)
float normalizedToQ(float normalized) noexcept;          // 0-1 → Q 0.1-20
float normalizedToDb(float normalized) noexcept;         // 0-1 → -24 to +24 dB

} // namespace audioapp