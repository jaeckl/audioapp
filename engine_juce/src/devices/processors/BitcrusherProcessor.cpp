#include "audioapp/devices/processors/BitcrusherProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <algorithm>
#include <cmath>

namespace audioapp {
namespace {
float softClip(float x) noexcept { return x / (1.0f + std::abs(x)); }

float fold(float x) noexcept {
    x = std::fmod(x + 1.0f, 4.0f);
    if (x < 0.0f) x += 4.0f;
    return x <= 2.0f ? x - 1.0f : 3.0f - x;
}
}

void BitcrusherProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<BitcrusherParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));

    const int mode = std::clamp(static_cast<int>(std::round(p.mode)), 0, 3);
    const int shape = std::clamp(static_cast<int>(std::round(p.shape)), 0, 3);
    const int ditherMode = std::clamp(static_cast<int>(std::round(p.ditherMode)), 0, 3);
    const int clipMode = std::clamp(static_cast<int>(std::round(p.clipMode)), 0, 2);
    const float modeDrive = mode == 1 ? .35f : mode == 2 ? .12f : 0.0f;
    const float modeJitter = mode == 3 ? .18f : 0.0f;
    const float driveGain = 1.0f + 15.0f * std::clamp(p.drive + modeDrive, 0.0f, 1.0f);
    const float bits = std::clamp(p.bits - (mode == 1 ? 1.0f : 0.0f), 1.0f, 16.0f);
    const float quantLevels = std::pow(2.0f, bits - 1.0f);
    const float baseHold = 1.0f + (1.0f - std::clamp(p.rate, 0.0f, 1.0f)) * 63.0f;
    const float jitter = std::clamp(p.jitter + modeJitter, 0.0f, 1.0f);
    const float mix = std::clamp(p.mix, 0.0f, 1.0f);
    const float cutoff = mode == 2
        ? 250.0f + 3750.0f * p.filter
        : 800.0f * std::pow(25.0f, std::clamp(p.filter, 0.0f, 1.0f));
    const float filterCoeff = 1.0f - std::exp(-6.283185307f * cutoff / static_cast<float>(ctx.sampleRate));
    float shapedError = 0.0f;

    auto randomBipolar = [&]() noexcept {
        randomState_ = randomState_ * 1664525u + 1013904223u;
        return static_cast<float>((randomState_ >> 8) & 0xffffu) / 32767.5f - 1.0f;
    };
    auto crush = [&](float input) noexcept {
        float value = input * driveGain;
        switch (shape) {
        case 1: value = std::tanh(value); break;
        case 2: value = fold(value); break;
        case 3: value = std::floor(value * 4.0f) * .25f; break;
        default: break;
        }
        const float lsb = 1.0f / quantLevels;
        float noise = 0.0f;
        if (ditherMode == 1) noise = randomBipolar();
        else if (ditherMode >= 2) noise = (randomBipolar() + randomBipolar()) * .5f;
        if (ditherMode == 3) noise += shapedError * .75f;
        const float before = value + noise * lsb * std::clamp(p.ditherAmount, 0.0f, 1.0f);
        float output = std::round(before * quantLevels) / quantLevels;
        shapedError = before - output;
        const float clip = std::clamp(p.clipAmount, 0.0f, 1.0f);
        if (clipMode == 1) output = softClip(output * (1.0f + clip * 8.0f)) / softClip(1.0f + clip * 8.0f);
        else if (clipMode == 2) {
            const float threshold = 1.0f - clip * .9f;
            output = std::clamp(output, -threshold, threshold);
        }
        return output;
    };

    for (int f = 0; f < block.numSamples; ++f) {
        const float dryL = block.channelL[f];
        const float dryR = block.channelR[f];
        phase_ += 1.0f;
        const float holdFrames = std::max(1.0f, baseHold * (1.0f + randomBipolar() * jitter * .45f));
        if (phase_ >= holdFrames) {
            phase_ = std::fmod(phase_, holdFrames);
            heldL_ = crush(dryL);
            heldR_ = mode == 2 ? heldL_ : crush(dryR);
        }
        filterL_ += filterCoeff * (heldL_ - filterL_);
        filterR_ += filterCoeff * (heldR_ - filterR_);
        block.channelL[f] = dryL * (1.0f - mix) + filterL_ * mix;
        block.channelR[f] = dryR * (1.0f - mix) + filterR_ * mix;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        const float peak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(peak, std::memory_order_relaxed);
    }
}
} // namespace audioapp
