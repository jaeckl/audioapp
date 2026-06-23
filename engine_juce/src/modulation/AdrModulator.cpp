#include "audioapp/modulation/AdrModulator.hpp"

namespace audioapp {

float AdrModulator::evaluate(double playheadBeat, int bpm,
                             double frameSeconds,
                             uint32_t retriggerGeneration) noexcept {
    (void)playheadBeat;
    (void)bpm;
    return evaluateOnNoteRetrigger(frameSeconds, retriggerGeneration);
}

float AdrModulator::evaluateOnNoteRetrigger(double frameSeconds,
                                            uint32_t retriggerGeneration) noexcept {
    if (retriggerGeneration != runtime_.lastRetriggerGeneration) {
        runtime_.lastRetriggerGeneration = retriggerGeneration;
        runtime_.level = 0.0f;
        runtime_.stage = 1;
        runtime_.segStartSeconds = frameSeconds;
    }

    const float attack = envelopeSegmentSeconds(params_.attack);
    const float decay = envelopeSegmentSeconds(params_.decay);
    const float release = envelopeSegmentSeconds(params_.release);
    const float elapsed = static_cast<float>(std::max(0.0, frameSeconds - runtime_.segStartSeconds));

    if (runtime_.stage == 1) {
        runtime_.level = attack > 0.0f ? std::min(1.0f, elapsed / attack) : 1.0f;
        if (elapsed >= attack) {
            runtime_.stage = 2;
            runtime_.segStartSeconds = frameSeconds;
        }
    } else if (runtime_.stage == 2) {
        const float t = static_cast<float>(frameSeconds - runtime_.segStartSeconds);
        runtime_.level = decay > 0.0f ? 1.0f - std::min(1.0f, t / decay) : 0.0f;
        if (t >= decay) {
            runtime_.stage = 4;  // skip stage 3 (sustain) for ADR
            runtime_.segStartSeconds = frameSeconds;
        }
    } else if (runtime_.stage == 4) {
        const float t = static_cast<float>(frameSeconds - runtime_.segStartSeconds);
        // ADR release starts from 0 (decay already reached 0), so level stays 0
        runtime_.level = 0.0f;
        if (t >= release) {
            runtime_.stage = 0;
            runtime_.level = 0.0f;
        }
    } else {
        runtime_.level = 0.0f;
    }

    return applyPolarity(runtime_.level * 2.0f - 1.0f, params_.polarity);
}

} // namespace audioapp