#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/ModulationTypes.hpp"

namespace audioapp {

/// Lightweight xorshift64 RNG — fits in 8 bytes, realtime-safe.
struct XorShiftRng {
    uint64_t state;

    explicit XorShiftRng() noexcept : state(1) {}
    explicit XorShiftRng(uint64_t seed) noexcept : state(seed | 1) {}

    float nextFloat() noexcept {
        state ^= state << 13;
        state ^= state >> 7;
        state ^= state << 17;
        // Map to [-1, 1]
        return static_cast<float>(static_cast<int64_t>(state)) * 2.3283064365e-10f;
    }
};

class RandomGeneratorModulator : public IModulator {
public:
    explicit RandomGeneratorModulator(const RandomGeneratorParams& params) noexcept
        : params_(params), rng_(1) {}

    void reset() noexcept override {
        rt_ = Runtime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::RandomGenerator);
    }

    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;

private:
    RandomGeneratorParams params_;
    XorShiftRng rng_;

    struct Runtime {
        float currentValue = 0.0f;
        float drawStartValue = 0.0f;
        double lastSampleTime = 0.0;
        double nextSampleTime = 0.0;
        int lastDivision = -1;
        uint32_t lastRetriggerGeneration = std::numeric_limits<uint32_t>::max();
    };
    Runtime rt_;

    float drawRandom() noexcept {
        return rng_.nextFloat();
    }

    static float clamp01(float value) noexcept {
        return std::clamp(value, 0.0f, 1.0f);
    }

    static float rateToHz(float normalizedRate) noexcept {
        return 0.05f + clamp01(normalizedRate) * 7.95f;
    }

    static float rateToSpeedMult(float normalizedRate) noexcept {
        return 0.25f + clamp01(normalizedRate) * 3.75f;
    }

    static double syncBeats(int syncDivision) noexcept {
        switch (syncDivision) {
        case 0:  return 0.0;
        case 1:  return 1.0;
        case 2:  return 0.5;
        case 3:  return 0.25;
        case 4:  return 0.125;
        case 5:  return 0.0625;
        default: return 0.25;
        }
    }
};

} // namespace audioapp