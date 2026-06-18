#include "audioapp/DynamicsProcessor.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

constexpr float kEps = 1.0e-10f;

float normToThresholdDb(float norm) noexcept {
    return -60.0f + std::clamp(norm, 0.0f, 1.0f) * 54.0f;
}

float normToAttackSec(float norm) noexcept {
    return 0.0005f + std::clamp(norm, 0.0f, 1.0f) * 0.05f;
}

float normToReleaseSec(float norm) noexcept {
    return 0.005f + std::clamp(norm, 0.0f, 1.0f) * 0.45f;
}

float normToHoldSec(float norm) noexcept {
    return std::clamp(norm, 0.0f, 1.0f) * 0.08f;
}

float normToRatio(float norm) noexcept {
    return 1.0f + std::clamp(norm, 0.0f, 1.0f) * 19.0f;
}

float normToExpanderRatio(float norm) noexcept {
    return 1.0f + std::clamp(norm, 0.0f, 1.0f) * 7.0f;
}

float normToKneeDb(float norm) noexcept {
    return std::clamp(norm, 0.0f, 1.0f) * 12.0f;
}

float normToMakeupDb(float norm) noexcept {
    return std::clamp(norm, 0.0f, 1.0f) * 18.0f;
}

float normToRangeDb(float norm) noexcept {
    return -80.0f + std::clamp(norm, 0.0f, 1.0f) * 80.0f;
}

float normToCeilingDb(float norm) noexcept {
    return -12.0f + std::clamp(norm, 0.0f, 1.0f) * 12.0f;
}

float linearToDb(float linear) noexcept {
    return 20.0f * std::log10(std::max(linear, kEps));
}

float dbToLinear(float db) noexcept {
    return std::pow(10.0f, db / 20.0f);
}

float smoothCoeff(float seconds, double sampleRate) noexcept {
    if (seconds <= 0.0f || sampleRate <= 0.0) {
        return 1.0f;
    }
    return 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * seconds));
}

float softKneeGainDb(float inputDb, float thresholdDb, float ratio, float kneeDb) noexcept {
    if (kneeDb <= 0.001f) {
        if (inputDb <= thresholdDb) {
            return 0.0f;
        }
        return (thresholdDb - inputDb) * (1.0f - 1.0f / ratio);
    }

    const float kneeStart = thresholdDb - kneeDb * 0.5f;
    const float kneeEnd = thresholdDb + kneeDb * 0.5f;
    if (inputDb <= kneeStart) {
        return 0.0f;
    }
    if (inputDb >= kneeEnd) {
        return (thresholdDb - inputDb) * (1.0f - 1.0f / ratio);
    }

    const float x = inputDb - kneeStart;
    const float slope = (1.0f - 1.0f / ratio) / (2.0f * kneeDb);
    return -slope * x * x;
}

void applyGainDb(float& left, float& right, float gainDb) noexcept {
    const float g = dbToLinear(gainDb);
    left *= g;
    right *= g;
}

void processDynamicsEnvelope(float detector,
                             double sampleRate,
                             float attackSec,
                             float releaseSec,
                             DynamicsRuntime& runtime) noexcept {
    const float attackCoeff = smoothCoeff(attackSec, sampleRate);
    const float releaseCoeff = smoothCoeff(releaseSec, sampleRate);
    const float coeff = detector > runtime.envelope ? attackCoeff : releaseCoeff;
    runtime.envelope += (detector - runtime.envelope) * coeff;
}

} // namespace

void processGateStereoBlock(float* trackLeft,
                            float* trackRight,
                            int numFrames,
                            double sampleRate,
                            const GateParams& params,
                            DynamicsRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const float thresholdDb = normToThresholdDb(params.gateThreshold);
    const float attackSec = normToAttackSec(params.gateAttack);
    const float releaseSec = normToReleaseSec(params.gateRelease);
    const float holdSec = normToHoldSec(params.gateHold);
    const float floorDb = normToRangeDb(params.gateRange);
    const float attackCoeff = smoothCoeff(attackSec, sampleRate);
    const float releaseCoeff = smoothCoeff(releaseSec, sampleRate);
    const float holdSamples = static_cast<float>(holdSec * sampleRate);

    for (int i = 0; i < numFrames; ++i) {
        const float detector = std::max(std::abs(trackLeft[i]), std::abs(trackRight[i]));
        const float detectorDb = linearToDb(detector);

        if (detectorDb >= thresholdDb) {
            runtime.holdSamples = holdSamples;
            runtime.envelope += (1.0f - runtime.envelope) * attackCoeff;
        } else if (runtime.holdSamples > 0.0f) {
            runtime.holdSamples -= 1.0f;
        } else {
            runtime.envelope += (0.0f - runtime.envelope) * releaseCoeff;
        }

        const float openDb = floorDb + runtime.envelope * (0.0f - floorDb);
        runtime.gainReductionDb = openDb;
        const float g = dbToLinear(openDb) * params.gain;
        trackLeft[i] *= g;
        trackRight[i] *= g;
    }
}

void processCompressorStereoBlock(float* trackLeft,
                                  float* trackRight,
                                  int numFrames,
                                  double sampleRate,
                                  const CompressorParams& params,
                                  DynamicsRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const float thresholdDb = normToThresholdDb(params.compThreshold);
    const float ratio = normToRatio(params.compRatio);
    const float attackSec = normToAttackSec(params.compAttack);
    const float releaseSec = normToReleaseSec(params.compRelease);
    const float kneeDb = normToKneeDb(params.compKnee);
    const float makeupDb = normToMakeupDb(params.compMakeup);

    for (int i = 0; i < numFrames; ++i) {
        const float detector = std::max(std::abs(trackLeft[i]), std::abs(trackRight[i]));
        processDynamicsEnvelope(detector, sampleRate, attackSec, releaseSec, runtime);

        const float envDb = linearToDb(runtime.envelope);
        const float grDb = softKneeGainDb(envDb, thresholdDb, ratio, kneeDb);
        runtime.gainReductionDb = grDb;
        applyGainDb(trackLeft[i], trackRight[i], grDb + makeupDb);
        trackLeft[i] *= params.gain;
        trackRight[i] *= params.gain;
    }
}

void processExpanderStereoBlock(float* trackLeft,
                                float* trackRight,
                                int numFrames,
                                double sampleRate,
                                const ExpanderParams& params,
                                DynamicsRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const float thresholdDb = normToThresholdDb(params.expandThreshold);
    const float ratio = normToExpanderRatio(params.expandRatio);
    const float attackSec = normToAttackSec(params.expandAttack);
    const float releaseSec = normToReleaseSec(params.expandRelease);
    const float floorDb = normToRangeDb(params.expandRange);

    for (int i = 0; i < numFrames; ++i) {
        const float detector = std::max(std::abs(trackLeft[i]), std::abs(trackRight[i]));
        processDynamicsEnvelope(detector, sampleRate, attackSec, releaseSec, runtime);

        const float envDb = linearToDb(runtime.envelope);
        float grDb = 0.0f;
        if (envDb < thresholdDb) {
            grDb = (thresholdDb - envDb) * (ratio - 1.0f);
            grDb = std::max(grDb, floorDb);
        }
        runtime.gainReductionDb = grDb;
        applyGainDb(trackLeft[i], trackRight[i], grDb);
        trackLeft[i] *= params.gain;
        trackRight[i] *= params.gain;
    }
}

void processLimiterStereoBlock(float* trackLeft,
                               float* trackRight,
                               int numFrames,
                               double sampleRate,
                               const LimiterParams& params,
                               DynamicsRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const float ceilingDb = normToCeilingDb(params.limitCeiling);
    const float releaseSec = normToReleaseSec(params.limitRelease);
    const float driveDb = params.limitDrive * 12.0f;
    const float releaseCoeff = smoothCoeff(releaseSec, sampleRate);

    for (int i = 0; i < numFrames; ++i) {
        float left = trackLeft[i] * dbToLinear(driveDb);
        float right = trackRight[i] * dbToLinear(driveDb);
        const float peak = std::max(std::abs(left), std::abs(right));
        const float peakDb = linearToDb(peak);

        float targetGrDb = 0.0f;
        if (peakDb > ceilingDb) {
            targetGrDb = ceilingDb - peakDb;
        }

        if (targetGrDb < runtime.gainReductionDb) {
            runtime.gainReductionDb = targetGrDb;
        } else {
            runtime.gainReductionDb += (targetGrDb - runtime.gainReductionDb) * releaseCoeff;
        }

        applyGainDb(left, right, runtime.gainReductionDb);
        trackLeft[i] = left * params.gain;
        trackRight[i] = right * params.gain;
    }
}

} // namespace audioapp
