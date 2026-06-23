#pragma once

#include <algorithm>
#include <cmath>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/LfoTypes.hpp"

namespace audioapp {

/// Modulator implementing a 4-stage ADSR envelope (attack-decay-sustain-release).
class AdsrModulator : public IModulator {
public:
    explicit AdsrModulator(const AdsrParams& params) noexcept : params_(params) {}

    void reset() noexcept override {
        runtime_ = EnvelopeRuntime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::Adsr);
    }

    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;

private:
    AdsrParams params_;
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

    /// Evaluate the envelope looped for sync mode (not used — ADSR is OnNote only).
    float evaluateSynced(double /*playheadBeat*/, int /*bpm*/, double /*frameSeconds*/) noexcept {
        return 0.0f;
    }

    float evaluateOnNoteRetrigger(double frameSeconds, uint32_t retriggerGeneration) noexcept;
};

} // namespace audioapp