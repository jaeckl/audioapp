#pragma once

namespace audioapp {

constexpr int kResonatorBandCount = 6;

struct ResonatorBankParams {
    float rootHz = 130.8128f;
    float spread = 1.0f;
    float decaySeconds = 1.25f;
    float damping = 0.35f;
    float colorDbPerOctave = 0.0f;
    float width = 1.0f;
    float mix = 0.5f;
};

struct ResonatorBandState {
    float x2 = 0.0f;
    float y1 = 0.0f;
    float y2 = 0.0f;
};

struct ResonatorBandCoefficients {
    float b = 0.0f;
    float a1 = 0.0f;
    float a2 = 0.0f;
    float gainL = 0.0f;
    float gainR = 0.0f;
};

struct ResonatorBankRuntime {
    ResonatorBandState states[kResonatorBandCount][2];
    ResonatorBandCoefficients coefficients[kResonatorBandCount];
    float smoothedMix = 0.5f;
    double sampleRate = 0.0;
    bool initialized = false;
};

void processResonatorBankStereoBlock(float* left,
                                     float* right,
                                     int numFrames,
                                     double sampleRate,
                                     const ResonatorBankParams& params,
                                     ResonatorBankRuntime& runtime) noexcept;

} // namespace audioapp
