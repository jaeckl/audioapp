#include "audioapp/modulation/SequencerModulator.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>

namespace audioapp {

void SequencerModulator::fisherYatesShuffle(int count, uint64_t seed) noexcept {
    for (int i = count - 1; i > 0; --i) {
        seed = seed * 6364136223846793005ULL + 1442695040888963407ULL;
        const int j = static_cast<int>(seed % static_cast<uint64_t>(i + 1));
        std::swap(rt_.randomOrder[i], rt_.randomOrder[j]);
    }
}

void SequencerModulator::shuffleRandomOrder() noexcept {
    const int count = std::max(1, params_.stepCount);
    // Fill with identity [0, 1, 2, ..., count-1]
    for (int i = 0; i < count; ++i) {
        rt_.randomOrder[i] = i;
    }
    // Deterministic seed from count so pattern is reproducible
    fisherYatesShuffle(count, static_cast<uint64_t>(count) * 6364136223846793005ULL + 1);
    rt_.randomIdx = 0;
}

float SequencerModulator::evaluateStepValue(int stepIndex, int nextStepIndexValue, double stepProgress) const noexcept {
    const int count = std::max(1, params_.stepCount);
    const int idx = std::clamp(stepIndex, 0, count - 1);
    const float current = params_.stepValues[static_cast<size_t>(idx)];

    if (params_.shape == 0) {
        // Hold — constant value throughout the entire step
        return current;
    }

    // For interpolation shapes, get the "next" step value
    const int nIdx = std::clamp(nextStepIndexValue, 0, count - 1);
    const float next = params_.stepValues[static_cast<size_t>(nIdx)];
    const float t = static_cast<float>(std::min(stepProgress, 1.0));

    if (params_.shape == 1) {
        // Linear — lerp from current to next
        return current + (next - current) * t;
    }

    // Smooth — cosine-interpolated ramp
    const float cosT = (1.0f - std::cos(t * 3.14159265f)) * 0.5f;
    return current + (next - current) * cosT;
}

bool SequencerModulator::usesPerNoteClock() const noexcept {
    return static_cast<ModulatorRetrigger>(params_.retrigger) == ModulatorRetrigger::OnNote;
}

float SequencerModulator::evaluate(double playheadBeat, int bpm,
                                   double secondsWithinBlock,
                                   double playheadSeconds,
                                   uint32_t retriggerGeneration,
                                   double noteElapsedSeconds) noexcept {
    const int count = std::max(1, params_.stepCount);
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);

    if (retrigger == ModulatorRetrigger::OnNote) {
        if (noteElapsedSeconds < 0.0) {
            return 0.0f;
        }
        if (rt_.lastNoteElapsedSeconds < 0.0
            || noteElapsedSeconds + 1.0e-4 < rt_.lastNoteElapsedSeconds) {
            rt_.currentStep = 0;
            rt_.lastAdvanceBeat = playheadBeat;
            rt_.sampleClock = 0.0;
            rt_.pingPongDir = 1;
            rt_.smoothedValue = 0.0f;
            shuffleRandomOrder();
        }
        rt_.lastNoteElapsedSeconds = noteElapsedSeconds;
    }

    // Compute step duration in seconds
    double stepDuration;
    if (retrigger == ModulatorRetrigger::Sync || retrigger == ModulatorRetrigger::OnNote) {
        // Beat-synchronized mode
        const double beatInterval = syncDivisionBeats(params_.syncDivision);
        stepDuration = (beatInterval * 60.0) / std::max(bpm, 1);
    } else {
        // Free mode: step duration from Hz rate
        stepDuration = 1.0 / std::max(rateToHz(params_.rate), 0.001f);
    }

    // Compute elapsed time for step advancement
    double elapsed;
    if (retrigger == ModulatorRetrigger::OnNote) {
        elapsed = noteElapsedSeconds;
    } else if (retrigger == ModulatorRetrigger::Free) {
        // Free-running: accumulate elapsed time from block duration
        rt_.sampleClock += secondsWithinBlock;
        elapsed = rt_.sampleClock;
    } else {
        // Sync or OnNote: use beats elapsed since lastAdvanceBeat
        const double beatDelta = playheadBeat - rt_.lastAdvanceBeat;
        elapsed = (beatDelta * 60.0) / std::max(bpm, 1);
    }

    // Determine current step index based on direction
    int stepIdx = 0;
    int interpNextIdx = 0; // for interpolation shapes
    if (stepDuration > 0.0) {
        const int rawStep = static_cast<int>(elapsed / stepDuration);

        // Lazily initialize random order for non-OnNote modes
        if (params_.direction == 3 && !rt_.randomInitialized) {
            shuffleRandomOrder();
            rt_.randomInitialized = true;
        }

        switch (params_.direction) {
        case 0: // Forward
            stepIdx = rawStep % count;
            interpNextIdx = (stepIdx + 1) % count;
            break;
        case 1: // Reverse
            stepIdx = (count - 1) - (rawStep % count);
            interpNextIdx = (stepIdx - 1 + count) % count;
            break;
        case 2: { // PingPong
            const int cycleLen = count * 2 - 2;
            if (cycleLen > 0) {
                const int pos = rawStep % cycleLen;
                stepIdx = (pos < count) ? pos : cycleLen - pos;
                rt_.pingPongDir = (pos < count) ? 1 : -1;
                // Next step for interpolation = one step in current direction
                if (rt_.pingPongDir > 0)
                    interpNextIdx = (stepIdx + 1) % count;
                else
                    interpNextIdx = (stepIdx - 1 + count) % count;
            }
            break;
        }
        case 3: { // Random
            // Advance through pre-shuffled randomOrder; reshuffle when exhausted
            if (rt_.randomIdx >= count) {
                shuffleRandomOrder();
            }
            stepIdx = rt_.randomOrder[rt_.randomIdx];
            interpNextIdx = rt_.randomOrder[(rt_.randomIdx + 1) % count];
            rt_.randomIdx = (rt_.randomIdx + 1) % (count + 1);
            if (rt_.randomIdx >= count) rt_.randomIdx = count;
            break;
        }
        }
    }

    rt_.currentStep = stepIdx;

    // Phase within the current step [0, 1)
    const double phase = (stepDuration > 0.0)
        ? std::fmod(elapsed, stepDuration) / stepDuration
        : 0.0;

    // Evaluate with shape interpolation
    const float rawValue = evaluateStepValue(stepIdx, interpNextIdx, phase);

    // Apply smoothing: single-pole lowpass
    // coefficient a = 1 - smoothing, so:
    //   smoothing=0 → a=1 → output=raw (no smoothing)
    //   smoothing=1 → a=0 → output frozen (fully smoothed)
    const float a = 1.0f - clamp01(params_.smoothing);
    rt_.smoothedValue += a * (rawValue - rt_.smoothedValue);
    float out = rt_.smoothedValue;

    // Apply polarity per contract §3.5
    // stepValues in [0, 1]. Bipolar (polarity=0): map [0,1] to [-1,1].
    // Unipolar positive (polarity=1): map [0,1] to [0,1].
    if (params_.polarity == 0) {
        out = out * 2.0f - 1.0f;
    }

    return out;
}

namespace {

void shuffleSequencerNoteOrder(const SequencerParams& params, SequencerModulator::NoteRuntimeState& state) {
    const int count = std::max(1, params.stepCount);
    for (int i = 0; i < count; ++i) {
        state.randomOrder[i] = i;
    }
    uint64_t seed = static_cast<uint64_t>(count) * 6364136223846793005ULL + 1;
    for (int i = count - 1; i > 0; --i) {
        seed = seed * 6364136223846793005ULL + 1442695040888963407ULL;
        const int j = static_cast<int>(seed % static_cast<uint64_t>(i + 1));
        std::swap(state.randomOrder[i], state.randomOrder[j]);
    }
    state.randomIdx = 0;
}

} // namespace

float SequencerModulator::evaluateForNote(double noteElapsedSeconds,
                                          int bpm,
                                          NoteRuntimeState& state) const noexcept {
    if (noteElapsedSeconds < 0.0) {
        return 0.0f;
    }
    if (state.lastNoteElapsed < 0.0
        || noteElapsedSeconds + 1.0e-4 < state.lastNoteElapsed) {
        state.smoothedValue = 0.0f;
        state.randomIdx = 0;
        state.randomInitialized = false;
        shuffleSequencerNoteOrder(params_, state);
    }
    state.lastNoteElapsed = noteElapsedSeconds;

    const int count = std::max(1, params_.stepCount);
    const double beatInterval = syncDivisionBeats(params_.syncDivision);
    const double stepDuration = (beatInterval * 60.0) / std::max(bpm, 1);
    const double elapsed = noteElapsedSeconds;

    int stepIdx = 0;
    int interpNextIdx = 0;
    if (stepDuration > 0.0) {
        const int rawStep = static_cast<int>(elapsed / stepDuration);
        if (params_.direction == 3 && !state.randomInitialized) {
            shuffleSequencerNoteOrder(params_, state);
            state.randomInitialized = true;
        }
        switch (params_.direction) {
        case 0:
            stepIdx = rawStep % count;
            interpNextIdx = (stepIdx + 1) % count;
            break;
        case 1:
            stepIdx = (count - 1) - (rawStep % count);
            interpNextIdx = (stepIdx - 1 + count) % count;
            break;
        case 2: {
            const int cycleLen = count * 2 - 2;
            if (cycleLen > 0) {
                const int pos = rawStep % cycleLen;
                stepIdx = (pos < count) ? pos : cycleLen - pos;
                const int pingPongDir = (pos < count) ? 1 : -1;
                interpNextIdx = pingPongDir > 0 ? (stepIdx + 1) % count : (stepIdx - 1 + count) % count;
            }
            break;
        }
        case 3:
            if (state.randomIdx >= count) {
                shuffleSequencerNoteOrder(params_, state);
            }
            stepIdx = state.randomOrder[state.randomIdx];
            interpNextIdx = state.randomOrder[(state.randomIdx + 1) % count];
            state.randomIdx = (state.randomIdx + 1) % (count + 1);
            if (state.randomIdx >= count) {
                state.randomIdx = count;
            }
            break;
        default:
            break;
        }
    }

    const double phase = stepDuration > 0.0
        ? std::fmod(elapsed, stepDuration) / stepDuration
        : 0.0;
    const float rawValue = evaluateStepValue(stepIdx, interpNextIdx, phase);
    const float a = 1.0f - clamp01(params_.smoothing);
    state.smoothedValue += a * (rawValue - state.smoothedValue);
    float out = state.smoothedValue;
    if (params_.polarity == 0) {
        out = out * 2.0f - 1.0f;
    }
    return out;
}

} // namespace audioapp