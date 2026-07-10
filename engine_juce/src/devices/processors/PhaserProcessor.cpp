#include "audioapp/devices/processors/PhaserProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {
constexpr float kPi = 3.14159265358979323846f;

float wrapUnit(float phase) noexcept {
    phase -= std::floor(phase);
    return phase < 0.0f ? phase + 1.0f : phase;
}

float skewPhase(float phase, float shape) noexcept {
    const float pivot = 0.15f + std::clamp(shape, 0.0f, 1.0f) * 0.70f;
    return phase < pivot
        ? 0.5f * phase / pivot
        : 0.5f + 0.5f * (phase - pivot) / (1.0f - pivot);
}

float oscillator(float phase, int waveform, float shape, float randomValue) noexcept {
    const float p = skewPhase(wrapUnit(phase), shape);
    switch (waveform) {
    case 1: return 1.0f - 4.0f * std::abs(p - 0.5f); // triangle
    case 2: return 2.0f * p - 1.0f;                  // ramp
    case 3: return randomValue;                      // sample and hold
    default: return std::sin(2.0f * kPi * p);        // sine
    }
}

float allPassCoefficient(float frequency, double sampleRate) noexcept {
    const float tangent = std::tan(kPi * frequency / static_cast<float>(sampleRate));
    return (tangent - 1.0f) / (tangent + 1.0f);
}
} // namespace

float PhaserProcessor::nextRandom() noexcept {
    randomState_ ^= randomState_ << 13;
    randomState_ ^= randomState_ >> 17;
    randomState_ ^= randomState_ << 5;
    return static_cast<float>(randomState_ & 0x00ffffffu) / 8388607.5f - 1.0f;
}

void PhaserProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<PhaserParamsPlayback>(*ctx.modulatedParams);

    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    const float depth = std::clamp(p.depth, 0.0f, 1.0f);
    const float fb = std::clamp(p.feedback, 0.0f, 0.95f);
    const float centreFreq = std::clamp(p.centreFrequencyHz, 20.0f, 20000.0f);
    const int rateMode = std::clamp(static_cast<int>(std::lround(p.rateMode)), 0, 3);
    const int waveform = std::clamp(static_cast<int>(std::lround(p.waveform)), 0, 3);
    const float waveShape = std::clamp(p.waveShape, 0.0f, 1.0f);
    const float phaseOffset = std::clamp(p.phaseOffset, 0.0f, 1.0f);
    const float stereoOffset = std::clamp(p.stereoPhase, 0.0f, 1.0f) * 0.5f;
    const int stages = std::clamp(static_cast<int>(std::lround(p.stages)), 2, 12);
    const float freeRate = std::clamp(p.rateHz, 0.05f, 10.0f);
    const float syncedRate = static_cast<float>(std::max(ctx.bpm, 1)) /
        (rateMode == 1 ? 15.0f : rateMode == 2 ? 30.0f : 60.0f);
    const float rateHz = rateMode == 0 ? freeRate : syncedRate;
    const float nyquistLimit = static_cast<float>(ctx.sampleRate * 0.45);

    for (int f = 0; f < block.numSamples; ++f) {
        const float dryL = block.channelL[f];
        const float dryR = block.channelR[f];

        lfoPhase_ += rateHz / static_cast<float>(ctx.sampleRate);
        if (lfoPhase_ >= 1.0f) {
            lfoPhase_ -= 1.0f;
            randomL_ = nextRandom();
            randomR_ = nextRandom();
        }

        const float lfoL = oscillator(lfoPhase_ + phaseOffset, waveform, waveShape, randomL_);
        const float lfoR = oscillator(lfoPhase_ + phaseOffset + stereoOffset, waveform, waveShape, randomR_);
        const float modFreqL = std::clamp(
            centreFreq * std::pow(2.0f, depth * 2.0f * lfoL), 20.0f, nyquistLimit);
        const float modFreqR = std::clamp(
            centreFreq * std::pow(2.0f, depth * 2.0f * lfoR), 20.0f, nyquistLimit);

        float wetL = dryL + fb * phaserStateL_[stages - 1];
        float wetR = dryR + fb * phaserStateR_[stages - 1];

        for (int i = 0; i < stages; ++i) {
            const float spacing = static_cast<float>(i) - 0.5f * static_cast<float>(stages - 1);
            const float stageFreqL = std::clamp(modFreqL * std::pow(2.0f, spacing * 0.11f), 20.0f, nyquistLimit);
            const float stageFreqR = std::clamp(modFreqR * std::pow(2.0f, spacing * 0.11f), 20.0f, nyquistLimit);
            const float coefficientL = allPassCoefficient(stageFreqL, ctx.sampleRate);
            const float coefficientR = allPassCoefficient(stageFreqR, ctx.sampleRate);

            const float xL = wetL;
            const float yL = coefficientL * xL + phaserStateL_[i];
            phaserStateL_[i] = xL - coefficientL * yL;
            wetL = yL;

            const float xR = wetR;
            const float yR = coefficientR * xR + phaserStateR_[i];
            phaserStateR_[i] = xR - coefficientR * yR;
            wetR = yR;
        }

        block.channelL[f] = 0.5f * (dryL + wetL);
        block.channelR[f] = 0.5f * (dryR + wetR);
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
