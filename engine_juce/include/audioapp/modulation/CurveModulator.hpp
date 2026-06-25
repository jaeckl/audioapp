#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/ModulationTypes.hpp"

namespace audioapp {

/// Audio-thread modulator for user-drawn breakpoint curves.
/// Evaluates by accumulating phase [0, 1), interpolating between
/// breakpoints at the current playhead position.
class CurveModulator : public IModulator {
public:
    explicit CurveModulator(const CurveParams& params) noexcept
        : params_(params) {}

    void reset() noexcept override {
        runtime_ = Runtime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::Curve);
    }

    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;

    void updateParams(const ModulatorParams& params) noexcept override {
        params_ = std::get<CurveParams>(params);
    }

private:
    CurveParams params_;
    struct Runtime {
        double phase = 0.0;
        float smoothOut = 0.0f;
        uint32_t lastRetriggerGeneration = std::numeric_limits<uint32_t>::max();
        double retriggerStartSeconds = 0.0;
    };
    Runtime runtime_;

    static float clamp01(float v) noexcept { return std::clamp(v, 0.0f, 1.0f); }
    static float rateToHz(float normalizedRate) noexcept {
        return 0.05f + clamp01(normalizedRate) * 7.95f;
    }
    static float rateToSpeedMult(float normalizedRate) noexcept {
        return 0.25f + clamp01(normalizedRate) * 3.75f;
    }
    static double syncBeats(int division) noexcept {
        switch (division) {
        case 0:  return 0.0;
        case 1:  return 1.0;
        case 2:  return 0.5;
        case 3:  return 0.25;
        case 4:  return 0.125;
        case 5:  return 0.0625;
        default: return 0.25;
        }
    }

    /// Evaluate curve at normalized t [0, 1] by interpolating breakpoints.
    float evaluateCurve(float t) const noexcept;

    float applyPolarity(float value, int polarity) const noexcept {
        switch (polarity) {
        case 0: return value;                        // bipolar
        case 1: return std::max(0.0f, value);        // unipolar-positive
        default: return value;
        }
    }
};

} // namespace audioapp