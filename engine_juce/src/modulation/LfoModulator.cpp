#include "audioapp/modulation/LfoModulator.hpp"

namespace audioapp {

float LfoModulator::evaluate(double playheadBeat, int bpm,
                             double secondsWithinBlock,
                             double playheadSeconds,
                             uint32_t retriggerGeneration) noexcept {
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);
    if (retrigger == ModulatorRetrigger::OnNote) {
        return evaluateOnNoteRetrigger(playheadSeconds + secondsWithinBlock, retriggerGeneration);
    }
    return evaluateSynced(playheadBeat, bpm, secondsWithinBlock, playheadSeconds);
}

float LfoModulator::evaluateSynced(double playheadBeat, int bpm,
                                   double secondsWithinBlock,
                                   double playheadSeconds) noexcept {
    double phase = static_cast<double>(params_.phase);
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);
    if (retrigger == ModulatorRetrigger::Free) {
        // Use absolute elapsed time so phase accumulates continuously
        // across block boundaries.
        phase += (playheadSeconds + secondsWithinBlock) * static_cast<double>(lfoRateToHz(params_.rate));
    } else {
        const double beatDuration = lfoSyncBeats(params_.syncDivision > 0 ? params_.syncDivision : 3);
        const double speedMult = static_cast<double>(lfoRateToSpeedMult(params_.rate));
        phase = beatDuration > 0.0 ? (playheadBeat / beatDuration) * speedMult : 0.0;
    }
    const float morph = params_.analogMode != 0 ? 0.0f : params_.morph;
    const float spread = params_.analogMode != 0 ? 0.5f : params_.spread;
    const float raw = evaluateMorph(morph, spread, static_cast<float>(phase));
    return applyPolarity(raw, params_.polarity);
}

float LfoModulator::evaluateOnNoteRetrigger(double absoluteSeconds,
                                            uint32_t retriggerGeneration) noexcept {
    if (retriggerGeneration != runtime_.lastRetriggerGeneration) {
        runtime_.lastRetriggerGeneration = retriggerGeneration;
        runtime_.level = 0.0f;
        runtime_.stage = 1;
        runtime_.segStartSeconds = absoluteSeconds;
    }

    const double elapsed = absoluteSeconds - runtime_.segStartSeconds;
    const float phase = static_cast<float>(elapsed * static_cast<double>(lfoRateToHz(params_.rate))
                                           + static_cast<double>(params_.phase));
    const float morph = params_.analogMode != 0 ? 0.0f : params_.morph;
    const float spread = params_.analogMode != 0 ? 0.5f : params_.spread;
    const float raw = evaluateMorph(morph, spread, phase);
    return applyPolarity(raw, params_.polarity);
}

} // namespace audioapp