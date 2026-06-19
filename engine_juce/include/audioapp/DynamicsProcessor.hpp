#pragma once

#include <cstdint>

namespace audioapp {

struct DynamicsRuntime {
    float envelope = 0.0f;
    float holdSamples = 0.0f;
    float gainReductionDb = 0.0f;
};

struct GateParams {
    float gain = 1.0f;
    float inputGain = 1.0f;
    float gateThreshold = 0.45f;
    float gateAttack = 0.25f;
    float gateRelease = 0.50f;
    float gateHold = 0.20f;
    float gateRange = 0.0f;
};

void processGateStereoBlock(float* trackLeft,
                            float* trackRight,
                            int numFrames,
                            double sampleRate,
                            const GateParams& params,
                            DynamicsRuntime& runtime) noexcept;

struct CompressorParams {
    float gain = 1.0f;
    float inputGain = 1.0f;
    float compThreshold = 0.55f;
    float compRatio = 0.50f;
    float compAttack = 0.20f;
    float compRelease = 0.55f;
    float compKnee = 0.25f;
    float compMakeup = 0.35f;
};

void processCompressorStereoBlock(float* trackLeft,
                                  float* trackRight,
                                  int numFrames,
                                  double sampleRate,
                                  const CompressorParams& params,
                                  DynamicsRuntime& runtime) noexcept;

struct ExpanderParams {
    float gain = 1.0f;
    float inputGain = 1.0f;
    float expandThreshold = 0.40f;
    float expandRatio = 0.45f;
    float expandAttack = 0.25f;
    float expandRelease = 0.55f;
    float expandRange = 0.15f;
};

void processExpanderStereoBlock(float* trackLeft,
                                float* trackRight,
                                int numFrames,
                                double sampleRate,
                                const ExpanderParams& params,
                                DynamicsRuntime& runtime) noexcept;

struct LimiterParams {
    float gain = 1.0f;
    float inputGain = 1.0f;
    float limitCeiling = 0.85f;
    float limitAttack = 0.10f;
    float limitRelease = 0.40f;
    float limitKnee = 0.0f;
    float limitDrive = 0.0f;
    float limitMakeup = 0.0f;
};

void processLimiterStereoBlock(float* trackLeft,
                               float* trackRight,
                               int numFrames,
                               double sampleRate,
                               const LimiterParams& params,
                               DynamicsRuntime& runtime) noexcept;

} // namespace audioapp
