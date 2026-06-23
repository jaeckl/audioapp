#include "audioapp/modulation/AdrModulator.hpp"

namespace audioapp {

float AdrModulator::evaluate(double playheadBeat, int bpm,
                             double secondsWithinBlock,
                             double playheadSeconds,
                             uint32_t retriggerGeneration) noexcept {
    (void)playheadBeat;
    (void)bpm;
    (void)secondsWithinBlock;
    return evaluateOnNoteRetrigger(playheadSeconds + secondsWithinBlock, retriggerGeneration);
}

float AdrModulator::evaluateOnNoteRetrigger(double absoluteSeconds,
                                            uint32_t retriggerGeneration) noexcept {
    if (retriggerGeneration != runtime_.lastRetriggerGeneration) {
        runtime_.lastRetriggerGeneration = retriggerGeneration;
        runtime_.level = 0.0f;
        runtime_.stage = 1;
        runtime_.segStartSeconds = absoluteSeconds;
    }

    const float attack = envelopeSegmentSeconds(params_.attack);
    const float decay = envelopeSegmentSeconds(params_.decay);
    const float release = envelopeSegmentSeconds(params_.release);
    const float elapsed = static_cast<float>(std::max(0.0, absoluteSeconds - runtime_.segStartSeconds));

    if (runtime_.stage == 1) {
        runtime_.level = attack > 0.0f ? std::min(1.0f, elapsed / attack) : 1.0f;
        if (elapsed >= attack) {
            runtime_.stage = 2;
            runtime_.segStartSeconds = absoluteSeconds;
        }
    } else if (runtime_.stage == 2) {
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        runtime_.level = decay > 0.0f ? 1.0f - std::min(1.0f, t / decay) : 0.0f;
        if (t >= decay) {
            runtime_.stage = 4;
            runtime_.segStartSeconds = absoluteSeconds;
        }
    } else if (runtime_.stage == 4) {
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
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