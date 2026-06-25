#pragma once

#include <algorithm>
#include <cmath>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/ModulationTypes.hpp"

namespace audioapp {

/// Unified envelope modulator supporting ADSR, ASR, ADR, and AHDSR curves.
/// Always retriggers on note — no free/sync/rate modes.
class EnvelopeModulator : public IModulator {
public:
    explicit EnvelopeModulator(const EnvelopeParams& params) noexcept : params_(params) {}

    void reset() noexcept override {
        runtime_ = EnvelopeRuntime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::Envelope);
    }

    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;

    void updateParams(const ModulatorParams& params) noexcept override {
        params_ = std::get<EnvelopeParams>(params);
    }

private:
    EnvelopeParams params_;
    EnvelopeRuntime runtime_;

    static float clamp01(float value) noexcept {
        return std::clamp(value, 0.0f, 1.0f);
    }

    static float envelopeSegmentSeconds(float normalized) noexcept {
        return std::max(0.01f, clamp01(normalized)) * 4.0f;
    }

    float evaluateOnNoteRetrigger(double absoluteSeconds,
                                  uint32_t retriggerGeneration) noexcept;
};

} // namespace audioapp