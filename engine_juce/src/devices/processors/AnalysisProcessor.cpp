#include "audioapp/devices/processors/AnalysisProcessor.hpp"

#include "audioapp/devices/processors/ProcessorUtils.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

AnalysisProcessor::AnalysisProcessor(DeviceNodeKind kind) noexcept : kind_(kind) {
    constexpr float kTwoPi = 6.28318530717958647692f;
    for (int sample = 0; sample < kFftSize; ++sample) {
        fftWindow_[static_cast<size_t>(sample)] = 0.5f - 0.5f * std::cos(
            kTwoPi * static_cast<float>(sample) /
            static_cast<float>(kFftSize - 1));
    }
}

void AnalysisProcessor::resetPlaybackState() noexcept {
    fftInputRing_.fill(0.0f);
    fftReal_.fill(0.0f);
    fftImag_.fill(0.0f);
    spectrumValues_.fill(0.0f);
    fftWriteIndex_ = 0;
    fftInputCount_ = 0;
    samplesSinceFft_ = 0;
    samplesUntilSpectrumPublish_ = 0;
    loudness_ = -70.0f;
}

void AnalysisProcessor::calculateSpectrum(double sampleRate,
                                          DeviceMeterAtomic& meter,
                                          bool publish) noexcept {
    float mean = 0.0f;
    for (const float sample : fftInputRing_) mean += sample;
    mean /= static_cast<float>(kFftSize);

    for (int sample = 0; sample < kFftSize; ++sample) {
        const int ringIndex = (fftWriteIndex_ + sample) & (kFftSize - 1);
        fftReal_[static_cast<size_t>(sample)] =
            (fftInputRing_[static_cast<size_t>(ringIndex)] - mean) *
            fftWindow_[static_cast<size_t>(sample)];
        fftImag_[static_cast<size_t>(sample)] = 0.0f;
    }

    for (int index = 1, reversed = 0; index < kFftSize; ++index) {
        int bit = kFftSize >> 1;
        for (; (reversed & bit) != 0; bit >>= 1) reversed ^= bit;
        reversed ^= bit;
        if (index < reversed) {
            std::swap(fftReal_[static_cast<size_t>(index)],
                      fftReal_[static_cast<size_t>(reversed)]);
            std::swap(fftImag_[static_cast<size_t>(index)],
                      fftImag_[static_cast<size_t>(reversed)]);
        }
    }

    constexpr float kTwoPi = 6.28318530717958647692f;
    for (int length = 2; length <= kFftSize; length <<= 1) {
        const float angle = -kTwoPi / static_cast<float>(length);
        const float stepReal = std::cos(angle);
        const float stepImag = std::sin(angle);
        const int half = length >> 1;
        for (int start = 0; start < kFftSize; start += length) {
            float twiddleReal = 1.0f;
            float twiddleImag = 0.0f;
            for (int offset = 0; offset < half; ++offset) {
                const int even = start + offset;
                const int odd = even + half;
                const float oddReal =
                    fftReal_[static_cast<size_t>(odd)] * twiddleReal -
                    fftImag_[static_cast<size_t>(odd)] * twiddleImag;
                const float oddImag =
                    fftReal_[static_cast<size_t>(odd)] * twiddleImag +
                    fftImag_[static_cast<size_t>(odd)] * twiddleReal;
                const float evenReal = fftReal_[static_cast<size_t>(even)];
                const float evenImag = fftImag_[static_cast<size_t>(even)];
                fftReal_[static_cast<size_t>(even)] = evenReal + oddReal;
                fftImag_[static_cast<size_t>(even)] = evenImag + oddImag;
                fftReal_[static_cast<size_t>(odd)] = evenReal - oddReal;
                fftImag_[static_cast<size_t>(odd)] = evenImag - oddImag;
                const float nextReal = twiddleReal * stepReal -
                    twiddleImag * stepImag;
                twiddleImag = twiddleReal * stepImag +
                    twiddleImag * stepReal;
                twiddleReal = nextReal;
            }
        }
    }

    constexpr float kMinimumFrequency = 20.0f;
    const float safeSampleRate = static_cast<float>(std::max(sampleRate, 1.0));
    const float maximumFrequency = std::min(
        20000.0f, safeSampleRate * 0.5f);
    const float logRange = std::log(maximumFrequency / kMinimumFrequency);
    const float magnitudeScale = 4.0f / static_cast<float>(kFftSize);
    for (int band = 0; band < 24; ++band) {
        const float low = kMinimumFrequency * std::exp(
            logRange * static_cast<float>(band) / 24.0f);
        const float high = kMinimumFrequency * std::exp(
            logRange * static_cast<float>(band + 1) / 24.0f);
        const int firstBin = std::max(1, static_cast<int>(std::ceil(
            low * static_cast<float>(kFftSize) /
            safeSampleRate)));
        const int lastBin = std::min(kFftSize / 2,
            std::max(firstBin, static_cast<int>(std::floor(
                high * static_cast<float>(kFftSize) /
                safeSampleRate))));
        float magnitude = 0.0f;
        for (int bin = firstBin; bin <= lastBin; ++bin) {
            magnitude = std::max(magnitude, std::hypot(
                fftReal_[static_cast<size_t>(bin)],
                fftImag_[static_cast<size_t>(bin)]) * magnitudeScale);
        }
        const float normalized = std::clamp(
            (20.0f * std::log10(std::max(magnitude, 1.0e-5f)) + 80.0f) /
                80.0f,
            0.0f, 1.0f);
        spectrumValues_[static_cast<size_t>(band)] = normalized;
        if (publish) {
            meter.spectrum[band].store(normalized, std::memory_order_relaxed);
        }
    }
}

void AnalysisProcessor::pushSpectrumSamples(const AudioBlock& block,
                                            ProcessContext& ctx,
                                            DeviceMeterAtomic& meter) noexcept {
    for (int frame = 0; frame < block.numSamples; ++frame) {
        --samplesUntilSpectrumPublish_;
        fftInputRing_[static_cast<size_t>(fftWriteIndex_)] =
            0.5f * (block.channelL[frame] + block.channelR[frame]);
        fftWriteIndex_ = (fftWriteIndex_ + 1) & (kFftSize - 1);
        fftInputCount_ = std::min(fftInputCount_ + 1, kFftSize);
        ++samplesSinceFft_;
        if (fftInputCount_ < kFftSize ||
            (samplesSinceFft_ < kFftHop && samplesSinceFft_ != kFftSize)) {
            continue;
        }
        const bool publish = samplesUntilSpectrumPublish_ <= 0;
        calculateSpectrum(ctx.sampleRate, meter, publish);
        samplesSinceFft_ = 0;
        if (publish) {
            samplesUntilSpectrumPublish_ = std::max(
                1, static_cast<int>(ctx.sampleRate / 60.0));
        }
    }
}

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
    if (kind_ == DeviceNodeKind::SpectrumAnalyzer) {
        pushSpectrumSamples(block, ctx, meter);
    }
}

} // namespace audioapp
