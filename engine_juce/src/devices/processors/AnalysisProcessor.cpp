#include "audioapp/devices/processors/AnalysisProcessor.hpp"

#include "audioapp/devices/processors/ProcessorUtils.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

void AnalysisProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (block.numSamples <= 0) {
        return;
    }

    if (kind_ == DeviceNodeKind::StereoImager) {
        const float width = std::clamp(outputWidth, 0.0f, 2.0f);
        for (int i = 0; i < block.numSamples; ++i) {
            const float mid = 0.5f * (block.channelL[i] + block.channelR[i]);
            const float side = 0.5f * (block.channelL[i] - block.channelR[i]) * width;
            block.channelL[i] = mid + side;
            block.channelR[i] = mid - side;
        }
    }

    if (!isMeterSlotSubscribed(ctx, meterSlot) || ctx.deviceMeters == nullptr ||
        meterSlot < 0 || meterSlot >= ctx.maxDeviceMeters) {
        return;
    }

    auto& meter = ctx.deviceMeters[meterSlot];
    float peak = 0.0f, sum = 0.0f, lr = 0.0f, ll = 0.0f, rr = 0.0f;
    for (int i = 0; i < block.numSamples; ++i) {
        const float l = block.channelL[i], r = block.channelR[i];
        peak = std::max(peak, std::max(std::abs(l), std::abs(r)));
        sum += 0.5f * (l * l + r * r);
        lr += l * r;
        ll += l * l;
        rr += r * r;
    }
    meter.inputPeak.store(peak, std::memory_order_relaxed);
    const float rms = std::sqrt(sum / static_cast<float>(block.numSamples));
    const float targetLufs = std::max(-70.0f, 20.0f * std::log10(std::max(rms, 0.00001f)) - 0.691f);
    loudness_ += 0.12f * (targetLufs - loudness_);
    meter.loudness.store(loudness_, std::memory_order_relaxed);
    meter.correlation.store(lr / std::sqrt(std::max(ll * rr, 1.0e-12f)), std::memory_order_relaxed);

    if (kind_ == DeviceNodeKind::Oscilloscope || kind_ == DeviceNodeKind::StereoImager) {
        for (int b = 0; b < 32; ++b) {
            const int i = std::min(block.numSamples - 1, b * block.numSamples / 32);
            const float v = kind_ == DeviceNodeKind::StereoImager
                ? ((b & 1) == 0 ? block.channelL[i] : block.channelR[i])
                : 0.5f * (block.channelL[i] + block.channelR[i]);
            meter.waveform[b].store(v, std::memory_order_relaxed);
        }
    }
    samplesUntilSpectrum_ -= block.numSamples;
    if (kind_ == DeviceNodeKind::SpectrumAnalyzer && samplesUntilSpectrum_ <= 0) {
        samplesUntilSpectrum_ = std::max(1, static_cast<int>(ctx.sampleRate / 60.0));
        constexpr float pi = 3.14159265358979323846f;
        for (int b = 0; b < 24; ++b) {
            const int bin = 1 + b * (block.numSamples / 2 - 1) / 24;
            float re = 0.0f, im = 0.0f;
            for (int i = 0; i < block.numSamples; ++i) {
                const float sample = 0.5f * (block.channelL[i] + block.channelR[i]);
                const float phase = 2.0f * pi * static_cast<float>(bin * i) / static_cast<float>(block.numSamples);
                re += sample * std::cos(phase);
                im -= sample * std::sin(phase);
            }
            const float mag = std::sqrt(re * re + im * im) / static_cast<float>(block.numSamples);
            meter.spectrum[b].store(
                std::clamp((20.0f * std::log10(std::max(mag, 1.0e-5f)) + 80.0f) / 80.0f, 0.0f, 1.0f),
                std::memory_order_relaxed);
        }
    }
}

} // namespace audioapp
