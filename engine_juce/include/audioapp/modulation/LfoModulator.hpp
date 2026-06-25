#pragma once

#include <algorithm>
#include <cmath>

#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/ModulationTypes.hpp"

namespace audioapp {

/// Modulator implementing LFO waveform + optional envelope for sync/on-note retrigger.
/// Stores a copy of LfoParams set at construction time.
class LfoModulator : public IModulator {
public:
    explicit LfoModulator(const LfoParams& params) noexcept : params_(params) {}

    void reset() noexcept override {
        runtime_ = EnvelopeRuntime{};
    }

    int modulatorType() const noexcept override {
        return static_cast<int>(ModulatorType::Lfo);
    }

    float evaluate(double playheadBeat, int bpm,
                   double secondsWithinBlock,
                   double playheadSeconds,
                   uint32_t retriggerGeneration) noexcept override;

    void updateParams(const ModulatorParams& params) noexcept override {
        params_ = std::get<LfoParams>(params);
    }

private:
    LfoParams params_;
    EnvelopeRuntime runtime_;

    static float clamp01(float value) noexcept {
        return std::clamp(value, 0.0f, 1.0f);
    }

    static float lfoRateToHz(float normalizedRate) noexcept {
        return 0.05f + clamp01(normalizedRate) * 7.95f;
    }

    static float lfoRateToSpeedMult(float normalizedRate) noexcept {
        return 0.25f + clamp01(normalizedRate) * 3.75f;
    }

    static float envelopeSegmentSeconds(float normalized) noexcept {
        return std::max(0.01f, clamp01(normalized)) * 4.0f;
    }

    static double lfoSyncBeats(int syncDivision) noexcept {
        switch (syncDivision) {
        case 0:  return 0.0;
        case 1:  return 1.0;
        case 2:  return 0.5;
        case 3:  return 0.25;
        case 4:  return 0.125;
        case 5:  return 0.0625;
        default: return 0.25;
        }
    }

    float evaluateWaveform(LfoWaveform waveform, float phase) const noexcept {
        phase = phase - std::floor(phase);
        switch (waveform) {
        case LfoWaveform::Sine:   return std::sin(phase * 6.283185307f);
        case LfoWaveform::Tri:    return 1.0f - 4.0f * std::abs(phase - 0.5f);
        case LfoWaveform::Saw:    return 2.0f * phase - 1.0f;
        case LfoWaveform::Square: return phase < 0.5f ? 1.0f : -1.0f;
        case LfoWaveform::Ramp:   return 1.0f - 2.0f * phase;
        }
        return 0.0f;
    }

    float applyPolarity(float value, int polarity) const noexcept {
        switch (polarity) {
        case 1: return std::max(0.0f, value);
        case 2: return std::min(0.0f, value);
        default: return value;
        }
    }

    float adsrSyncedValue(float progress, bool includeSustain) const noexcept {
        const float attack = envelopeSegmentSeconds(params_.attack);
        const float decay = envelopeSegmentSeconds(params_.decay);
        const float sustainHold = includeSustain ? envelopeSegmentSeconds(params_.sustain) * 0.5f : 0.0f;
        const float release = envelopeSegmentSeconds(params_.release);
        const float total = attack + decay + sustainHold + release;
        if (total <= 0.0f) return 0.0f;
        float t = progress * total;
        if (t < attack) return t / attack;
        t -= attack;
        if (t < decay) {
            const float susLevel = includeSustain ? clamp01(params_.sustain) : 0.0f;
            return 1.0f - (1.0f - susLevel) * (t / decay);
        }
        t -= decay;
        if (includeSustain && t < sustainHold) return clamp01(params_.sustain);
        t -= sustainHold;
        if (t < release) {
            const float start = includeSustain ? clamp01(params_.sustain) : 0.0f;
            return start * (1.0f - t / release);
        }
        return 0.0f;
    }

    float evaluateSynced(double playheadBeat, int bpm, double frameSeconds, double playheadSeconds) noexcept;
    float evaluateOnNoteRetrigger(double frameSeconds, uint32_t retriggerGeneration) noexcept;
};

} // namespace audioapp