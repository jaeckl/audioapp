#include "audioapp/modulation/RandomGeneratorModulator.hpp"

namespace audioapp {

bool RandomGeneratorModulator::usesPerNoteClock() const noexcept {
    return static_cast<ModulatorRetrigger>(params_.retrigger) == ModulatorRetrigger::OnNote;
}

float RandomGeneratorModulator::evaluate(double playheadBeat, int bpm,
                                         double secondsWithinBlock,
                                         double playheadSeconds,
                                         uint32_t retriggerGeneration,
                                         double noteElapsedSeconds) noexcept {
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);

    if (retrigger == ModulatorRetrigger::OnNote) {
        if (noteElapsedSeconds < 0.0) {
            return 0.0f;
        }
        if (rt_.lastNoteElapsedSeconds < 0.0
            || noteElapsedSeconds + 1.0e-4 < rt_.lastNoteElapsedSeconds) {
            rt_.nextSampleTime = -1.0;
            rt_.lastDivision = -1;
            rt_.currentValue = 0.0f;
            rt_.drawStartValue = 0.0f;
        }
        rt_.lastNoteElapsedSeconds = noteElapsedSeconds;
    }

    double currentPhase = 0.0;

    if (retrigger == ModulatorRetrigger::Sync) {
        // Sync mode: beat-synchronized sample & hold
        const int syncIndex = std::clamp(static_cast<int>(params_.rate * 5.99f), 0, 5);
        const double beatInterval = syncBeats(syncIndex);
        if (beatInterval <= 0.0) return 0.0f;

        const double speedMult = rateToSpeedMult(params_.rate);
        const double effectivePeriod = beatInterval / speedMult;
        const int currentDivision = static_cast<int>(playheadBeat / effectivePeriod);

        if (currentDivision != rt_.lastDivision) {
            rt_.drawStartValue = rt_.currentValue;
            rt_.currentValue = drawRandom();
            rt_.lastDivision = currentDivision;
            rt_.lastSampleTime = static_cast<double>(currentDivision) * effectivePeriod;
        }

        const double divisionElapsed = playheadBeat - rt_.lastSampleTime;
        currentPhase = effectivePeriod > 0.0 ? divisionElapsed / effectivePeriod : 0.0;
    } else {
        // Free mode (and OnNote after reset): time-based sample & hold
        const double absTime = retrigger == ModulatorRetrigger::OnNote
            ? noteElapsedSeconds
            : (playheadSeconds + secondsWithinBlock);
        const double rateHzVal = rateToHz(params_.rate);
        const double period = 1.0 / rateHzVal;

        // Initialize on first call
        if (rt_.nextSampleTime <= 0.0) {
            rt_.currentValue = drawRandom();
            rt_.drawStartValue = rt_.currentValue;
            rt_.lastSampleTime = absTime;
            rt_.nextSampleTime = absTime + period;
        }

        // Draw new values at each rate boundary
        while (absTime >= rt_.nextSampleTime) {
            rt_.drawStartValue = rt_.currentValue;
            rt_.currentValue = drawRandom();
            rt_.lastSampleTime = rt_.nextSampleTime;
            rt_.nextSampleTime += period;
        }

        const double periodElapsed = absTime - rt_.lastSampleTime;
        const double periodLength = rt_.nextSampleTime - rt_.lastSampleTime;
        currentPhase = periodLength > 0.0 ? periodElapsed / periodLength : 0.0;
    }

    // Apply smoothing
    float result;
    if (params_.smoothing <= 0.0f || currentPhase >= 1.0) {
        result = rt_.currentValue;
    } else {
        const float slewFraction = std::min(params_.smoothing, 1.0f);
        const float t = static_cast<float>(currentPhase);
        if (t < slewFraction) {
            const float ramp = slewFraction > 0.001f ? t / slewFraction : 1.0f;
            result = rt_.drawStartValue + (rt_.currentValue - rt_.drawStartValue) * ramp;
        } else {
            result = rt_.currentValue;
        }
    }

    // Apply polarity: unipolar maps [-1, 1] to [0, 1]
    if (params_.polarity == 1) {
        result = result * 0.5f + 0.5f;
    }

    return result;
}

float RandomGeneratorModulator::evaluateForNote(double noteElapsedSeconds,
                                                NoteRuntimeState& state) noexcept {
    if (noteElapsedSeconds < 0.0) {
        return 0.0f;
    }
    if (state.lastNoteElapsed < 0.0
        || noteElapsedSeconds + 1.0e-4 < state.lastNoteElapsed) {
        state.nextSampleTime = -1.0;
        state.lastDivision = -1;
        state.currentValue = 0.0f;
        state.drawStartValue = 0.0f;
    }
    state.lastNoteElapsed = noteElapsedSeconds;

    const double absTime = noteElapsedSeconds;
    const double rateHzVal = rateToHz(params_.rate);
    const double period = 1.0 / rateHzVal;

    if (state.nextSampleTime <= 0.0) {
        state.currentValue = drawRandom();
        state.drawStartValue = state.currentValue;
        state.lastSampleTime = absTime;
        state.nextSampleTime = absTime + period;
    }

    while (absTime >= state.nextSampleTime) {
        state.drawStartValue = state.currentValue;
        state.currentValue = drawRandom();
        state.lastSampleTime = state.nextSampleTime;
        state.nextSampleTime += period;
    }

    const double periodElapsed = absTime - state.lastSampleTime;
    const double periodLength = state.nextSampleTime - state.lastSampleTime;
    const double currentPhase =
        periodLength > 0.0 ? periodElapsed / periodLength : 0.0;

    float result;
    if (params_.smoothing <= 0.0f || currentPhase >= 1.0) {
        result = state.currentValue;
    } else {
        const float slewFraction = std::min(params_.smoothing, 1.0f);
        const float t = static_cast<float>(currentPhase);
        if (t < slewFraction) {
            const float ramp = slewFraction > 0.001f ? t / slewFraction : 1.0f;
            result = state.drawStartValue + (state.currentValue - state.drawStartValue) * ramp;
        } else {
            result = state.currentValue;
        }
    }

    if (params_.polarity == 1) {
        result = result * 0.5f + 0.5f;
    }
    return result;
}

} // namespace audioapp