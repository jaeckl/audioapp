#include "audioapp/ProjectJson.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

float clamp01(float value) noexcept {
    return std::clamp(value, 0.0f, 1.0f);
}

/// UI knob 0..1 → free-running LFO frequency (Hz).
float lfoRateToHz(float normalizedRate) noexcept {
    return 0.05f + clamp01(normalizedRate) * 7.95f;
}

/// UI knob 0..1 → tempo-sync speed multiplier (0.25× … 4×).
float lfoRateToSpeedMult(float normalizedRate) noexcept {
    return 0.25f + clamp01(normalizedRate) * 3.75f;
}

float envelopeSegmentSeconds(float normalized) noexcept {
    return std::max(0.01f, clamp01(normalized)) * 4.0f;
}

float adsrSyncedValue(float progress, const LfoState& state, bool includeSustain) noexcept {
    const float attack = envelopeSegmentSeconds(state.attack);
    const float decay = envelopeSegmentSeconds(state.decay);
    const float sustainHold = includeSustain ? envelopeSegmentSeconds(state.sustain) * 0.5f : 0.0f;
    const float release = envelopeSegmentSeconds(state.release);
    const float total = attack + decay + sustainHold + release;
    if (total <= 0.0f) {
        return 0.0f;
    }
    float t = progress * total;
    if (t < attack) {
        return t / attack;
    }
    t -= attack;
    if (t < decay) {
        const float susLevel = includeSustain ? clamp01(state.sustain) : 0.0f;
        return 1.0f - (1.0f - susLevel) * (t / decay);
    }
    t -= decay;
    if (includeSustain && t < sustainHold) {
        return clamp01(state.sustain);
    }
    t -= sustainHold;
    if (t < release) {
        const float start = includeSustain ? clamp01(state.sustain) : 0.0f;
        return start * (1.0f - t / release);
    }
    return 0.0f;
}

} // namespace

float lfoEvaluate(LfoWaveform waveform, float phase) noexcept {
    phase = phase - std::floor(phase);
    switch (waveform) {
    case LfoWaveform::Sine:
        return std::sin(phase * 6.283185307f);
    case LfoWaveform::Tri:
        return 1.0f - 4.0f * std::abs(phase - 0.5f);
    case LfoWaveform::Saw:
        return 2.0f * phase - 1.0f;
    case LfoWaveform::Square:
        return phase < 0.5f ? 1.0f : -1.0f;
    case LfoWaveform::Ramp:
        return 1.0f - 2.0f * phase;
    }
    return 0.0f;
}

double lfoSyncBeats(int syncDivision) noexcept {
    switch (syncDivision) {
    case 0:
        return 0.0;
    case 1:
        return 1.0;
    case 2:
        return 0.5;
    case 3:
        return 0.25;
    case 4:
        return 0.125;
    case 5:
        return 0.0625;
    default:
        return 0.25;
    }
}

float modulatorApplyPolarity(float value, int polarity) noexcept {
    switch (polarity) {
    case 1:
        return std::max(0.0f, value);
    case 2:
        return std::min(0.0f, value);
    default:
        return value;
    }
}

float modulatorEvaluateSynced(const LfoState& state,
                              double playheadBeat,
                              int bpm,
                              double frameSeconds) noexcept {
    const auto type = static_cast<ModulatorType>(state.modulatorType);
    if (type == ModulatorType::Adsr || type == ModulatorType::Adr) {
        const float attack = envelopeSegmentSeconds(state.attack);
        const float decay = envelopeSegmentSeconds(state.decay);
        const float sustainHold =
            type == ModulatorType::Adsr ? envelopeSegmentSeconds(state.sustain) * 0.5f : 0.0f;
        const float release = envelopeSegmentSeconds(state.release);
        const double cycleSeconds =
            static_cast<double>(attack + decay + sustainHold + release);
        const double cycleBeats = cycleSeconds * static_cast<double>(std::max(bpm, 1)) / 60.0;
        const double beatDuration = lfoSyncBeats(state.syncDivision > 0 ? state.syncDivision : 3);
        const double loopBeats = beatDuration > 0.0 ? beatDuration : std::max(cycleBeats, 0.25);
        const double frameBeat =
            playheadBeat + frameSeconds * static_cast<double>(std::max(bpm, 1)) / 60.0;
        double progress = loopBeats > 0.0 ? std::fmod(frameBeat / loopBeats, 1.0) : 0.0;
        if (progress < 0.0) {
            progress += 1.0;
        }
        progress = std::fmod(progress + static_cast<double>(state.phase), 1.0);
        const float raw = adsrSyncedValue(static_cast<float>(progress),
                                          state,
                                          type == ModulatorType::Adsr);
        return modulatorApplyPolarity(raw * 2.0f - 1.0f, state.polarity);
    }

    double phase = static_cast<double>(state.phase);
    const auto retrigger = static_cast<ModulatorRetrigger>(state.retrigger);
    if (retrigger == ModulatorRetrigger::Free) {
        phase += frameSeconds * static_cast<double>(lfoRateToHz(state.rate));
    } else {
        const double beatDuration = lfoSyncBeats(state.syncDivision > 0 ? state.syncDivision : 3);
        const double speedMult = static_cast<double>(lfoRateToSpeedMult(state.rate));
        const double frameBeat =
            playheadBeat + frameSeconds * static_cast<double>(std::max(bpm, 1)) / 60.0;
        phase = beatDuration > 0.0 ? (frameBeat / beatDuration) * speedMult : 0.0;
    }
    const float raw = lfoEvaluate(static_cast<LfoWaveform>(state.waveform), static_cast<float>(phase));
    return modulatorApplyPolarity(raw, state.polarity);
}

float modulatorEvaluateOnNote(const LfoState& state,
                              double frameSeconds,
                              uint32_t retriggerGeneration,
                              uint32_t& lastRetriggerGeneration,
                              float& envelopeLevel,
                              int& envelopeStage,
                              double& segStartSeconds) noexcept {
    const auto type = static_cast<ModulatorType>(state.modulatorType);
    if (retriggerGeneration != lastRetriggerGeneration) {
        lastRetriggerGeneration = retriggerGeneration;
        envelopeLevel = 0.0f;
        envelopeStage = 1;
        segStartSeconds = frameSeconds;
    }

    if (type == ModulatorType::Lfo) {
        const double elapsed = frameSeconds - segStartSeconds;
        const float phase =
            static_cast<float>(elapsed * static_cast<double>(lfoRateToHz(state.rate)) +
                               static_cast<double>(state.phase));
        const float raw = lfoEvaluate(static_cast<LfoWaveform>(state.waveform), phase);
        return modulatorApplyPolarity(raw, state.polarity);
    }

    const float attack = envelopeSegmentSeconds(state.attack);
    const float decay = envelopeSegmentSeconds(state.decay);
    const float sustainLevel = clamp01(state.sustain);
    const float release = envelopeSegmentSeconds(state.release);
    const bool includeSustain = type == ModulatorType::Adsr;
    const float elapsed = static_cast<float>(std::max(0.0, frameSeconds - segStartSeconds));

    if (envelopeStage == 1) {
        envelopeLevel = attack > 0.0f ? std::min(1.0f, elapsed / attack) : 1.0f;
        if (elapsed >= attack) {
            envelopeStage = 2;
            segStartSeconds = frameSeconds;
        }
    } else if (envelopeStage == 2) {
        const float t = static_cast<float>(frameSeconds - segStartSeconds);
        const float target = includeSustain ? sustainLevel : 0.0f;
        envelopeLevel = decay > 0.0f ? 1.0f - (1.0f - target) * std::min(1.0f, t / decay) : target;
        if (t >= decay) {
            if (includeSustain) {
                envelopeStage = 3;
            } else {
                envelopeStage = 4;
                segStartSeconds = frameSeconds;
            }
        }
    } else if (envelopeStage == 3) {
        envelopeLevel = sustainLevel;
        envelopeStage = 4;
        segStartSeconds = frameSeconds;
    } else if (envelopeStage == 4) {
        const float t = static_cast<float>(frameSeconds - segStartSeconds);
        const float start = includeSustain ? sustainLevel : 0.0f;
        envelopeLevel = release > 0.0f ? start * (1.0f - std::min(1.0f, t / release)) : 0.0f;
        if (t >= release) {
            envelopeStage = 0;
            envelopeLevel = 0.0f;
        }
    } else {
        envelopeLevel = 0.0f;
    }

    return modulatorApplyPolarity(envelopeLevel * 2.0f - 1.0f, state.polarity);
}

} // namespace audioapp
