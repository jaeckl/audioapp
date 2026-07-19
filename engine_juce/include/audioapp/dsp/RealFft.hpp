#pragma once

// Compile-time FFT backend for real-only STFT.
// AUDIOAPP_USE_NEON_FFT=1 → in-tree radix-2 (ARM NEON butterflies when present).
// Otherwise → juce::dsp::FFT.

#include <cstdint>

#if !defined(AUDIOAPP_USE_NEON_FFT) || !AUDIOAPP_USE_NEON_FFT
#include <juce_dsp/juce_dsp.h>
#endif

namespace audioapp {

/// Real-only FFT with JUCE packed layout:
///   [0]=DC, [1]=Nyquist, [2*k]=re(k), [2*k+1]=im(k).
/// Buffer length must be >= 2 * size. Inverse scales by 1/size (round-trip ≈ id).
class RealFft final {
public:
    explicit RealFft(int order) noexcept;
    ~RealFft();

    RealFft(const RealFft&) = delete;
    RealFft& operator=(const RealFft&) = delete;

    int getSize() const noexcept { return size_; }

    void forwardRealOnly(float* data) noexcept;
    void inverseRealOnly(float* data) noexcept;

private:
    int order_ = 0;
    int size_ = 0;

#if defined(AUDIOAPP_USE_NEON_FFT) && AUDIOAPP_USE_NEON_FFT
    struct Tables;
    Tables* tables_ = nullptr;
#else
    juce::dsp::FFT fft_;
#endif
};

} // namespace audioapp
