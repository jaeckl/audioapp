#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/RealFft.hpp"

#include <array>

namespace audioapp {

class AnalysisProcessor final : public DeviceProcessor {
public:
    explicit AnalysisProcessor(DeviceNodeKind kind) noexcept;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return kind_; }
    void resetPlaybackState() noexcept override;
private:
    static constexpr int kFftOrder = 11;
    static constexpr int kFftSize = 1 << kFftOrder;
    static constexpr int kFftHop = kFftSize / 4;

    void pushSpectrumSamples(const AudioBlock& block, ProcessContext& ctx,
                             DeviceMeterAtomic& meter) noexcept;
    void calculateSpectrum(double sampleRate, DeviceMeterAtomic& meter,
                           bool publish) noexcept;

    DeviceNodeKind kind_;
    float loudness_ = -70.0f;
    std::array<float, kFftSize> fftInputRing_{};
    std::array<float, kFftSize> fftWindow_{};
    RealFft fft_{kFftOrder};
    std::array<float, kFftSize * 2> fftBuffer_{};
    std::array<float, 24> spectrumValues_{};
    int fftWriteIndex_ = 0;
    int fftInputCount_ = 0;
    int samplesSinceFft_ = 0;
    int samplesUntilSpectrumPublish_ = 0;
};

}
