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

// --- Frequency Shifter ---
struct FrequencyShifterParams {
    float shiftHz = 0.0f;     // -2000 to +2000 Hz
};

struct FrequencyShifterRuntime {
    double phaseL = 0.0;
    double phaseR = 0.0;
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