#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/ModulationTypes.hpp"

namespace audioapp {

/// Audio-thread modulator that evaluates a step sequencer pattern in real-time.
/// SequencerParams fields control direction, shape, smoothing, polarity, and step values.
class SequencerModulator : public IModulator {
public:
    explicit SequencerModulator(const SequencerParams& params) noexcept : params_(params) {}

    void reset() noexcept override {
        rt_ = Runtime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::Sequencer);
    }

    bool usesPerNoteClock() const noexcept override;

    void updateParams(const ModulatorParams& params) noexcept override {
        params_ = std::get<SequencerParams>(params);
    }

    struct NoteRuntimeState {
        float smoothedValue = 0.0f;
        int randomOrder[32]{};
        int randomIdx = 0;
        bool randomInitialized = false;
        double lastNoteElapsed = -1.0;
    };

    float evaluateForNote(double noteElapsedSeconds, int bpm, NoteRuntimeState& state) const noexcept;

    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration,
                   double noteElapsedSeconds) noexcept override;

private:
    SequencerParams params_;
    struct Runtime {
        int currentStep = 0;                                     // [0, stepCount-1]
        int pingPongDir = 1;                                     // +1 or -1 for PingPong
        double lastAdvanceBeat = 0.0;                            // beat of last retrigger
        uint32_t lastRetriggerGeneration = std::numeric_limits<uint32_t>::max();
        float smoothedValue = 0.0f;                              // smoothing filter state
        double sampleClock = 0.0;                                // free-running clock (Free mode)
        int randomOrder[32] = {};                                 // pre-shuffled indices (Random direction)
        int randomIdx = 0;                                        // position in randomOrder
        bool randomInitialized = false;                           // whether randomOrder has been shuffled
        double lastNoteElapsedSeconds = -1.0;
    };
    Runtime rt_;

    /// Evaluate the step value at the given index with shape-dependent interpolation.
    /// @param stepIndex The current step index.
    /// @param nextStepIndex The "next" step index for Linear/Smooth shapes.
    /// @param stepProgress Phase within the current step [0, 1).
    float evaluateStepValue(int stepIndex, int nextStepIndex, double stepProgress) const noexcept;

    /// Shuffle the randomOrder array using deterministic Fisher-Yates.
    void shuffleRandomOrder() noexcept;

    /// Instantiate a Fisher-Yates shuffle of the first `count` slots of randomOrder.
    void fisherYatesShuffle(int count, uint64_t seed) noexcept;

    static float rateToHz(float normalizedRate) noexcept {
        return 0.05f + std::clamp(normalizedRate, 0.0f, 1.0f) * 7.95f;
    }

    static double syncDivisionBeats(int div) noexcept {
        switch (div) {
        case 0:  return 0.0;
        case 1:  return 1.0;      // whole
        case 2:  return 0.5;      // half
        case 3:  return 0.25;     // quarter
        case 4:  return 0.125;    // eighth
        case 5:  return 0.0625;   // sixteenth
        default: return 0.25;
        }
    }

    static float clamp01(float v) noexcept {
        return std::clamp(v, 0.0f, 1.0f);
    }
};

} // namespace audioapp