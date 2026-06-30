#include "audioapp/modulation/EnvelopeModulator.hpp"

#include <cmath>

namespace audioapp {

/// Map curvature param [0,1] to ease-in (0) / linear (0.5) / ease-out (1).
/// Returns the eased progress for a linear input t in [0,1].
static float easeCurve(float t, float curve) noexcept {
    if (t <= 0.0f) return 0.0f;
    if (t >= 1.0f) return 1.0f;
    if (curve < 0.5f) {
        // ease-in (concave): slow start
        const float exp = 1.0f + 4.0f * (0.5f - curve);
        return std::pow(t, exp);
    } else {
        // ease-out (convex): fast start
        const float exp = 1.0f + 4.0f * (curve - 0.5f);
        return 1.0f - std::pow(1.0f - t, exp);
    }
}

float EnvelopeModulator::evaluate(double playheadBeat, int bpm,
                                  double secondsWithinBlock,
                                  double playheadSeconds,
                                  uint32_t retriggerGeneration,
                                  double noteElapsedSeconds) noexcept {
    (void)playheadBeat;
    (void)bpm;
    (void)secondsWithinBlock;
    if (noteElapsedSeconds >= 0.0) {
        return levelAtElapsed(noteElapsedSeconds);
    }
    return evaluateOnNoteRetrigger(playheadSeconds + secondsWithinBlock, retriggerGeneration);
}

float EnvelopeModulator::levelAtElapsed(double elapsedSeconds) const noexcept {
    if (elapsedSeconds <= 0.0) {
        return 0.0f;
    }
    float t = static_cast<float>(elapsedSeconds);

    const float delay = envelopeSegmentSeconds(params_.delay);
    const float attack = envelopeSegmentSeconds(params_.attack);
    const float hold = envelopeSegmentSeconds(params_.hold);
    const float decay = envelopeSegmentSeconds(params_.decay);
    const float sustainLevel = clamp01(params_.sustain);
    const float release = envelopeSegmentSeconds(params_.release);
    const float sustainHold = envelopeSegmentSeconds(params_.sustain);
    const int curve = params_.curveType;
    const bool hasSustain = (curve != static_cast<int>(EnvelopeCurve::Adr));
    const bool hasHold = (curve == static_cast<int>(EnvelopeCurve::Ahdsr));
    const bool hasDecay = (curve != static_cast<int>(EnvelopeCurve::Asr));

    if (t < delay) {
        return 0.0f;
    }
    t -= delay;

    {
        const float pct = attack > 0.0f ? std::min(1.0f, t / attack) : 1.0f;
        const float curveAmt = params_.analogMode ? 0.85f : params_.attackCurve;
        const float level = easeCurve(pct, curveAmt);
        if (t < attack) {
            return level;
        }
        t -= attack;
    }

    if (hasHold) {
        if (t < hold) {
            return 1.0f;
        }
        t -= hold;
    }

    if (hasDecay) {
        const float pct = decay > 0.0f ? std::min(1.0f, t / decay) : 1.0f;
        const float curveAmt = params_.analogMode ? 0.2f : params_.decayCurve;
        const float eased = easeCurve(pct, curveAmt);
        const float level =
            hasSustain ? 1.0f - (1.0f - sustainLevel) * eased : 1.0f - eased;
        if (t < decay) {
            return level;
        }
        t -= decay;
    }

    if (hasSustain) {
        if (t < sustainHold) {
            return sustainLevel;
        }
        t -= sustainHold;
    }

    {
        const float pct = release > 0.0f ? std::min(1.0f, t / release) : 1.0f;
        const float curveAmt = params_.analogMode ? 0.2f : params_.releaseCurve;
        const float eased = easeCurve(pct, curveAmt);
        return hasSustain ? sustainLevel * (1.0f - eased) : 1.0f - eased;
    }
}

float EnvelopeModulator::evaluateOnNoteRetrigger(double absoluteSeconds,
                                                 uint32_t retriggerGeneration) noexcept {
    if (retriggerGeneration != runtime_.lastRetriggerGeneration) {
        runtime_.lastRetriggerGeneration = retriggerGeneration;
        runtime_.level = 0.0f;
        runtime_.stage = 0; // start at delay stage
        runtime_.segStartSeconds = absoluteSeconds;
    }

    const float delay = envelopeSegmentSeconds(params_.delay);
    const float attack = envelopeSegmentSeconds(params_.attack);
    const float hold = envelopeSegmentSeconds(params_.hold);
    const float decay = envelopeSegmentSeconds(params_.decay);
    const float sustainLevel = clamp01(params_.sustain);
    const float release = envelopeSegmentSeconds(params_.release);
    const int curve = params_.curveType;
    const bool hasSustain = (curve != static_cast<int>(EnvelopeCurve::Adr));
    const bool hasHold = (curve == static_cast<int>(EnvelopeCurve::Ahdsr));
    const bool hasDecay = (curve != static_cast<int>(EnvelopeCurve::Asr));

    // Stages:
    //   0 = Delay (all)
    //   1 = Attack (all)
    //   2 = Hold (AHDSR only)
    //   3 = Decay (ADSR, ADR, AHDSR) / skip for ASR
    //   4 = Sustain level (ADSR, AHDSR, ASR) / skip for ADR
    //   5 = Release (all)

    if (runtime_.stage == 0) {
        // Delay (pre-delay before attack)
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        runtime_.level = 0.0f;
        if (t >= delay) {
            runtime_.stage = 1;
            runtime_.segStartSeconds = absoluteSeconds;
        }
    } else if (runtime_.stage == 1) {
        // Attack
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        const float pct = attack > 0.0f ? std::min(1.0f, t / attack) : 1.0f;
        const float curve = params_.analogMode ? 0.85f : params_.attackCurve;
        runtime_.level = easeCurve(pct, curve);
        if (t >= attack) {
            runtime_.segStartSeconds = absoluteSeconds;
            if (hasHold) runtime_.stage = 2;
            else if (hasDecay) runtime_.stage = 3;
            else if (hasSustain) runtime_.stage = 4;
            else runtime_.stage = 5;
        }
    } else if (runtime_.stage == 2) {
        // Hold (AHDSR only)
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        runtime_.level = 1.0f;
        if (t >= hold) {
            runtime_.stage = 3;
            runtime_.segStartSeconds = absoluteSeconds;
        }
    } else if (runtime_.stage == 3) {
        // Decay
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        const float pct = decay > 0.0f ? std::min(1.0f, t / decay) : 1.0f;
        const float curve = params_.analogMode ? 0.2f : params_.decayCurve;
        const float eased = easeCurve(pct, curve);
        if (hasSustain) {
            runtime_.level = 1.0f - (1.0f - sustainLevel) * eased;
        } else {
            runtime_.level = 1.0f - eased;
        }
        if (t >= decay) {
            runtime_.segStartSeconds = absoluteSeconds;
            if (hasSustain) runtime_.stage = 4;
            else runtime_.stage = 5;
        }
    } else if (runtime_.stage == 4) {
        // Sustain level
        runtime_.level = sustainLevel;
        const float sustainHold = envelopeSegmentSeconds(params_.sustain);
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        if (t >= sustainHold) {
            runtime_.stage = 5;
            runtime_.segStartSeconds = absoluteSeconds;
        }
    } else if (runtime_.stage == 5) {
        // Release
        const float t = static_cast<float>(absoluteSeconds - runtime_.segStartSeconds);
        const float pct = release > 0.0f ? std::min(1.0f, t / release) : 1.0f;
        const float curve = params_.analogMode ? 0.2f : params_.releaseCurve;
        const float eased = easeCurve(pct, curve);
        runtime_.level = hasSustain
            ? sustainLevel * (1.0f - eased)
            : 1.0f * (1.0f - eased);
        if (t >= release) {
            runtime_.stage = 0;
            runtime_.level = 0.0f;
        }
    } else {
        runtime_.level = 0.0f;
    }

    return runtime_.level;
}

float EnvelopeModulator::evaluateOnNoteElapsed(double noteElapsedSeconds) const noexcept {
    return levelAtElapsed(noteElapsedSeconds);
}

} // namespace audioapp