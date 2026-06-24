#include "audioapp/modulation/RandomGeneratorModulator.hpp"

namespace audioapp {

float RandomGeneratorModulator::evaluate(double playheadBeat, int bpm,
                                         double secondsWithinBlock,
                                         double playheadSeconds,
                                         uint32_t retriggerGeneration) noexcept {
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);

    // Handle OnNote retrigger: reset clock state
    if (retrigger == ModulatorRetrigger::OnNote) {
        if (retriggerGeneration != rt_.lastRetriggerGeneration) {
            rt_.lastRetriggerGeneration = retriggerGeneration;
            rt_.nextSampleTime = -1.0;
            rt_.lastDivision = -1;
            rt_.currentValue = 0.0f;
            rt_.drawStartValue = 0.0f;
        }
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
        const double absTime = playheadSeconds + secondsWithinBlock;
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

} // namespace audioapp