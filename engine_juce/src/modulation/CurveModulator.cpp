#include "audioapp/modulation/CurveModulator.hpp"

namespace audioapp {

float CurveModulator::evaluate(double playheadBeat, int bpm,
                               double secondsWithinBlock,
                               double playheadSeconds,
                               uint32_t retriggerGeneration) noexcept {
    const auto retrigger = static_cast<ModulatorRetrigger>(params_.retrigger);

    if (retrigger == ModulatorRetrigger::Free) {
        // Phase from absolute elapsed time, linear across frames
        runtime_.phase = std::fmod((playheadSeconds + secondsWithinBlock)
                                   * static_cast<double>(rateToHz(params_.rate)), 1.0);
    } else if (retrigger == ModulatorRetrigger::Sync) {
        const double beatDuration = syncBeats(params_.syncDivision > 0 ? params_.syncDivision : 3);
        const double speedMult = static_cast<double>(rateToSpeedMult(params_.rate));
        if (beatDuration > 0.0) {
            // Phase from absolute beat position, linear across frames (same as LFO)
            runtime_.phase = std::fmod((playheadBeat / beatDuration) * speedMult, 1.0);
        } else {
            runtime_.phase = 0.0;
        }
    } else {
        // OnNote retrigger — elapsed time since note-on (like LFO)
        if (retriggerGeneration != runtime_.lastRetriggerGeneration) {
            runtime_.lastRetriggerGeneration = retriggerGeneration;
            runtime_.phase = 0.0;
            runtime_.smoothOut = 0.0f;
            runtime_.retriggerStartSeconds = playheadSeconds + secondsWithinBlock;
        }
        const double elapsedSec = (playheadSeconds + secondsWithinBlock) - runtime_.retriggerStartSeconds;
        runtime_.phase = std::fmod(elapsedSec * static_cast<double>(rateToHz(params_.rate)), 1.0);
    }

    float raw = evaluateCurve(static_cast<float>(runtime_.phase));
    raw = applyPolarity(raw, params_.polarity);

    // Optional smoothing (single-pole lowpass)
    if (params_.smoothing > 0.001f) {
        const float coeff = std::clamp(params_.smoothing * 0.5f, 0.0f, 0.99f);
        raw = runtime_.smoothOut + coeff * (raw - runtime_.smoothOut);
        runtime_.smoothOut = raw;
    }

    return raw;
}

float CurveModulator::evaluateCurve(float t) const noexcept {
    const int count = std::clamp(params_.breakpointCount, 2, 64);
    const auto& bp = params_.breakpoints;

    // Wrap t to [0, 1]
    t = t - std::floor(t);

    // Find surrounding breakpoints
    int lo = 0;
    int hi = count - 1;
    for (int i = 0; i < count - 1; ++i) {
        if (t >= bp[i].position && t < bp[i + 1].position) {
            lo = i;
            hi = i + 1;
            break;
        }
    }

    const float posLo = bp[lo].position;
    const float posHi = bp[hi].position;
    const float span = posHi - posLo;
    if (span <= 0.001f) return bp[lo].value;

    const float local = (t - posLo) / span; // [0, 1] within segment

    switch (bp[lo].shape) {
    case 1: { // smooth (cubic hermite)
        const float v0 = bp[lo].value;
        const float v1 = bp[hi].value;
        // Hermite basis
        const float t2 = local * local;
        const float t3 = t2 * local;
        const float h00 = 2.0f * t3 - 3.0f * t2 + 1.0f;
        const float h10 = t3 - 2.0f * t2 + local;
        const float h01 = -2.0f * t3 + 3.0f * t2;
        const float h11 = t3 - t2;
        // Simple tangents: slope = (v1 - v0) / span (catmull-rom style)
        const float m0 = (v1 - v0) * 0.5f;
        const float m1 = m0;
        return h00 * v0 + h10 * m0 + h01 * v1 + h11 * m1;
    }
    case 2: // step
        return bp[lo].value;
    default: // linear
        return bp[lo].value + (bp[hi].value - bp[lo].value) * local;
    }
}

} // namespace audioapp