#include "audioapp/modulation/LfoModulator.hpp"

namespace audioapp {

float LfoModulator::evaluate(double playheadBeat, int bpm,
                             double frameSeconds,
                             uint32_t retriggerGeneration) noexcept {
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);
    if (retrigger == ModulatorRetrigger::OnNote) {
        return evaluateOnNoteRetrigger(frameSeconds, retriggerGeneration);
    }
    return evaluateSynced(playheadBeat, bpm, frameSeconds);
}

float LfoModulator::evaluateSynced(double playheadBeat, int bpm,
                                   double frameSeconds) noexcept {
    double phase = static_cast<double>(params_.phase);
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);
    if (retrigger == ModulatorRetrigger::Free) {
        phase += frameSeconds * static_cast<double>(lfoRateToHz(params_.rate));
    } else {
        const double beatDuration = lfoSyncBeats(params_.syncDivision > 0 ? params_.syncDivision : 3);
        const double speedMult = static_cast<double>(lfoRateToSpeedMult(params_.rate));
        const double frameBeat = playheadBeat + frameSeconds * static_cast<double>(std::max(bpm, 1)) / 60.0;
        phase = beatDuration > 0.0 ? (frameBeat / beatDuration) * speedMult : 0.0;
    }
    const float raw = evaluateWaveform(static_cast<LfoWaveform>(params_.waveform), static_cast<float>(phase));
    return applyPolarity(raw, params_.polarity);
}

float LfoModulator::evaluateOnNoteRetrigger(double frameSeconds,
                                            uint32_t retriggerGeneration) noexcept {
    if (retriggerGeneration != runtime_.lastRetriggerGeneration) {
        runtime_.lastRetriggerGeneration = retriggerGeneration;
        runtime_.level = 0.0f;
        runtime_.stage = 1;
        runtime_.segStartSeconds = frameSeconds;
    }

    const double elapsed = frameSeconds - runtime_.segStartSeconds;
    const float phase = static_cast<float>(elapsed * static_cast<double>(lfoRateToHz(params_.rate))
                                           + static_cast<double>(params_.phase));
    const float raw = evaluateWaveform(static_cast<LfoWaveform>(params_.waveform), phase);
    return applyPolarity(raw, params_.polarity);
}

} // namespace audioapp