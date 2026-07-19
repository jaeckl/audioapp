#include "audioapp/dsp/RealFft.hpp"

#include <cmath>
#include <cstring>
#include <memory>
#include <new>

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define AUDIOAPP_FFT_HAS_NEON 1
#endif

namespace audioapp {

#if defined(AUDIOAPP_USE_NEON_FFT) && AUDIOAPP_USE_NEON_FFT

struct RealFft::Tables {
    int size = 0;
    std::unique_ptr<float[]> twiddleRe;
    std::unique_ptr<float[]> twiddleIm;
    std::unique_ptr<int[]> bitrev;
    std::unique_ptr<float[]> workRe;
    std::unique_ptr<float[]> workIm;
};

namespace {

void bitReversePermute(float* re, float* im, const int* bitrev, int n) noexcept {
    for (int i = 0; i < n; ++i) {
        const int j = bitrev[i];
        if (j > i) {
            std::swap(re[i], re[j]);
            std::swap(im[i], im[j]);
        }
    }
}

void fftRadix2(float* re, float* im, const float* twRe, const float* twIm, int n,
               bool inverse) noexcept {
    for (int len = 2; len <= n; len <<= 1) {
        const int half = len >> 1;
        const int step = n / len;
        for (int i = 0; i < n; i += len) {
            for (int k = 0; k < half; ++k) {
                const int even = i + k;
                const int odd = even + half;
                const int tw = k * step;
                const float tr = twRe[tw];
                const float ti = inverse ? twIm[tw] : -twIm[tw];
                const float or_ = re[odd] * tr - im[odd] * ti;
                const float oi = re[odd] * ti + im[odd] * tr;
                const float er = re[even];
                const float ei = im[even];
                re[even] = er + or_;
                im[even] = ei + oi;
                re[odd] = er - or_;
                im[odd] = ei - oi;
            }
        }
    }
}

#if defined(AUDIOAPP_FFT_HAS_NEON)
void scaleBufferNeon(float* data, int n, float scale) noexcept {
    int i = 0;
    const float32x4_t s = vdupq_n_f32(scale);
    for (; i + 4 <= n; i += 4)
        vst1q_f32(data + i, vmulq_f32(vld1q_f32(data + i), s));
    for (; i < n; ++i) data[i] *= scale;
}
#endif

} // namespace

RealFft::RealFft(int order) noexcept {
    if (order < 2 || order > 12) return;
    order_ = order;
    size_ = 1 << order;
    tables_ = new (std::nothrow) Tables();
    if (tables_ == nullptr) {
        order_ = 0;
        size_ = 0;
        return;
    }
    tables_->size = size_;
    tables_->twiddleRe.reset(new (std::nothrow) float[static_cast<size_t>(size_ / 2)]);
    tables_->twiddleIm.reset(new (std::nothrow) float[static_cast<size_t>(size_ / 2)]);
    tables_->bitrev.reset(new (std::nothrow) int[static_cast<size_t>(size_)]);
    tables_->workRe.reset(new (std::nothrow) float[static_cast<size_t>(size_)]);
    tables_->workIm.reset(new (std::nothrow) float[static_cast<size_t>(size_)]);
    if (!tables_->twiddleRe || !tables_->twiddleIm || !tables_->bitrev || !tables_->workRe ||
        !tables_->workIm) {
        delete tables_;
        tables_ = nullptr;
        order_ = 0;
        size_ = 0;
        return;
    }

    const float twoPi = 6.28318530717958647692f;
    for (int i = 0; i < size_ / 2; ++i) {
        const float angle = twoPi * static_cast<float>(i) / static_cast<float>(size_);
        tables_->twiddleRe[static_cast<size_t>(i)] = std::cos(angle);
        tables_->twiddleIm[static_cast<size_t>(i)] = std::sin(angle);
    }
    for (int i = 0; i < size_; ++i) {
        int rev = 0;
        int v = i;
        for (int b = 0; b < order_; ++b) {
            rev = (rev << 1) | (v & 1);
            v >>= 1;
        }
        tables_->bitrev[static_cast<size_t>(i)] = rev;
    }
}

RealFft::~RealFft() {
    delete tables_;
    tables_ = nullptr;
}

void RealFft::forwardRealOnly(float* data) noexcept {
    if (tables_ == nullptr || data == nullptr || size_ <= 0) return;
    float* re = tables_->workRe.get();
    float* im = tables_->workIm.get();
    std::memcpy(re, data, sizeof(float) * static_cast<size_t>(size_));
    std::memset(im, 0, sizeof(float) * static_cast<size_t>(size_));
    bitReversePermute(re, im, tables_->bitrev.get(), size_);
    fftRadix2(re, im, tables_->twiddleRe.get(), tables_->twiddleIm.get(), size_, false);

    // Pack Hermitian spectrum into JUCE real-only layout.
    data[0] = re[0];
    data[1] = re[size_ / 2];
    for (int k = 1; k < size_ / 2; ++k) {
        data[2 * k] = re[k];
        data[2 * k + 1] = im[k];
    }
}

void RealFft::inverseRealOnly(float* data) noexcept {
    if (tables_ == nullptr || data == nullptr || size_ <= 0) return;
    float* re = tables_->workRe.get();
    float* im = tables_->workIm.get();

    re[0] = data[0];
    im[0] = 0.0f;
    re[size_ / 2] = data[1];
    im[size_ / 2] = 0.0f;
    for (int k = 1; k < size_ / 2; ++k) {
        re[k] = data[2 * k];
        im[k] = data[2 * k + 1];
        re[size_ - k] = re[k];
        im[size_ - k] = -im[k];
    }

    bitReversePermute(re, im, tables_->bitrev.get(), size_);
    fftRadix2(re, im, tables_->twiddleRe.get(), tables_->twiddleIm.get(), size_, true);

    const float scale = 1.0f / static_cast<float>(size_);
#if defined(AUDIOAPP_FFT_HAS_NEON)
    std::memcpy(data, re, sizeof(float) * static_cast<size_t>(size_));
    scaleBufferNeon(data, size_, scale);
#else
    for (int i = 0; i < size_; ++i)
        data[i] = re[i] * scale;
#endif
}

#else // juce backend

RealFft::RealFft(int order) noexcept : fft_(order) {
    order_ = order;
    size_ = 1 << order;
}

RealFft::~RealFft() = default;

void RealFft::forwardRealOnly(float* data) noexcept {
    fft_.performRealOnlyForwardTransform(data);
}

void RealFft::inverseRealOnly(float* data) noexcept {
    fft_.performRealOnlyInverseTransform(data);
}

#endif

} // namespace audioapp
