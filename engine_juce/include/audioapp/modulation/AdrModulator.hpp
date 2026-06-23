#pragma once

#include <algorithm>
#include <cmath>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/LfoTypes.hpp"

namespace audioapp {

/// Modulator implementing a 3-stage ADR envelope (attack-decay-release, no sustain).
class AdrModulator : public IModulator {
public:
    explicit AdrModulator(const AdrParams& params) noexcept : params_(params) {}

    void reset() noexcept override {
        runtime_ = EnvelopeRuntime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::Adr);
    }

    float evaluate(double playheadBeat, int bpm,
                   double frameSeconds,
                   uint32_t retriggerGeneration) noexcept override;

private:
    AdrParams params_;
    EnvelopeRuntime runtime_;

    static float clamp01(float value) noexcept {
        return std::clamp(value, 0.0f, 1.0f);
    }

    static float envelopeSegmentSeconds(float normalized) noexcept {
        return std::max(0.01f, clamp01(normalized)) * 4.0f;
    }

    float applyPolarity(float value, int polarity) const noexcept {
        switch (polarity) {
        case 1: return std::max(0.0f, value);
        case 2: return std::min(0.0f, value);
        default: return value;
        }
    }

    float evaluateOnNoteRetrigger(double frameSeconds, uint32_t retriggerGeneration) noexcept;
};

} // namespace audioapp