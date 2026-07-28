#include "audioapp/SubtractiveMorphTable.hpp"

#include <algorithm>
#include <cmath>
#include <vector>

namespace audioapp {
namespace {

constexpr float kPi = 3.14159265358979323846f;
constexpr float kTwoPi = 6.28318530718f;

static inline float safeClamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

static void normalizePeak(float* out, int n) noexcept {
    float peak = 1.0e-6f;
    for (int i = 0; i < n; ++i) {
        peak = std::max(peak, std::abs(out[i]));
    }
    const float scale = 1.0f / peak;
    for (int i = 0; i < n; ++i) {
        out[i] *= scale;
    }
}

/// Bandlimited / closed-form cycle for one morph frame at base length only.
static void fillBaseFrame(float* out, int n, int wave) noexcept {
    if (out == nullptr || n <= 0) {
        return;
    }
    const float invN = 1.0f / static_cast<float>(n);
    const int maxHarm = std::max(1, n / 2 - 1);

    switch (wave) {
    case 0:
        for (int i = 0; i < n; ++i) {
            out[i] = std::sin(kTwoPi * static_cast<float>(i) * invN);
        }
        break;
    case 1:
        for (int i = 0; i < n; ++i) {
            float s = 0.0f;
            for (int h = 1; h <= maxHarm; h += 2) {
                const float sign = ((h - 1) / 2) % 2 == 0 ? 1.0f : -1.0f;
                s += sign * std::sin(kTwoPi * static_cast<float>(h * i) * invN)
                    / static_cast<float>(h * h);
            }
            out[i] = s * (8.0f / (kPi * kPi));
        }
        break;
    case 2:
        for (int i = 0; i < n; ++i) {
            float s = 0.0f;
            for (int h = 1; h <= maxHarm; ++h) {
                s += std::sin(kTwoPi * static_cast<float>(h * i) * invN)
                    / static_cast<float>(h);
            }
            out[i] = s * (2.0f / kPi);
        }
        break;
    case 3:
        for (int i = 0; i < n; ++i) {
            float s = 0.0f;
            for (int h = 1; h <= maxHarm; h += 2) {
                s += std::sin(kTwoPi * static_cast<float>(h * i) * invN)
                    / static_cast<float>(h);
            }
            out[i] = s * (4.0f / kPi);
        }
        break;
    case 4:
    default: {
        for (int i = 0; i < n; ++i) {
            const float phase = kTwoPi * static_cast<float>(i) * invN;
            out[i] = phase < kPi ? 1.0f : -0.2f;
        }
        break;
    }
    }
    normalizePeak(out, n);
}

static void downsampleFrame(const float* src, int srcLen, float* dst, int dstLen) noexcept {
    // Box downsample 2:1 (srcLen must be 2 * dstLen).
    for (int i = 0; i < dstLen; ++i) {
        dst[i] = 0.5f * (src[i * 2] + src[i * 2 + 1]);
    }
    normalizePeak(dst, dstLen);
}

} // namespace

struct SubtractiveMorphTable::Storage {
    std::vector<float> pcm;
    int mipOffsets[kMipCount]{};
};

SubtractiveMorphTable::SubtractiveMorphTable() {
    storage_ = new Storage();
    int total = 0;
    for (int mip = 0; mip < kMipCount; ++mip) {
        storage_->mipOffsets[mip] = total;
        total += kFrames * (kBaseLength >> mip);
    }
    storage_->pcm.assign(static_cast<size_t>(total), 0.0f);
    pcm_ = storage_->pcm.data();
    for (int mip = 0; mip < kMipCount; ++mip) {
        mipOffsets_[mip] = storage_->mipOffsets[mip];
    }

    // Bake base mip with bandlimited additive, then downsample for higher mips
    // (avoids O(n²) sin sums on every mip — was multi-million ops at first use).
    float* base = pcm_ + mipOffsets_[0];
    for (int frame = 0; frame < kFrames; ++frame) {
        fillBaseFrame(base + frame * kBaseLength, kBaseLength, frame);
    }
    for (int mip = 1; mip < kMipCount; ++mip) {
        const int srcLen = kBaseLength >> (mip - 1);
        const int dstLen = kBaseLength >> mip;
        const float* srcMip = pcm_ + mipOffsets_[mip - 1];
        float* dstMip = pcm_ + mipOffsets_[mip];
        for (int frame = 0; frame < kFrames; ++frame) {
            downsampleFrame(srcMip + frame * srcLen, srcLen,
                            dstMip + frame * dstLen, dstLen);
        }
    }
}

const SubtractiveMorphTable& SubtractiveMorphTable::instance() noexcept {
    static const SubtractiveMorphTable table;
    return table;
}

int SubtractiveMorphTable::lengthForMip(int mip) const noexcept {
    const int m = std::clamp(mip, 0, kMipCount - 1);
    return kBaseLength >> m;
}

int SubtractiveMorphTable::pickMip(float rootHz, float sampleRate) const noexcept {
    const float hz = std::max(rootHz, 1.0f);
    const float sr = std::max(sampleRate, 1.0f);
    const float maxLen = sr / hz;
    for (int mip = 0; mip < kMipCount; ++mip) {
        if (static_cast<float>(kBaseLength >> mip) <= maxLen) {
            return mip;
        }
    }
    return kMipCount - 1;
}

const float* SubtractiveMorphTable::frameData(int mip, int frame) const noexcept {
    const int m = std::clamp(mip, 0, kMipCount - 1);
    const int f = std::clamp(frame, 0, kFrames - 1);
    const int len = kBaseLength >> m;
    return pcm_ + mipOffsets_[m] + f * len;
}

float SubtractiveMorphTable::lookupMip(float shape, float phaseRadians, int mip) const noexcept {
    const int m = std::clamp(mip, 0, kMipCount - 1);
    const int len = kBaseLength >> m;
    const float fi = safeClamp(shape, 0.0f, 1.0f) * static_cast<float>(kFrames - 1);
    const int frameA = static_cast<int>(fi);
    const int frameB = std::min(frameA + 1, kFrames - 1);
    const float frameFrac = fi - static_cast<float>(frameA);

    float p = phaseRadians * (1.0f / kTwoPi);
    p -= std::floor(p);
    if (p < 0.0f) {
        p += 1.0f;
    }
    const float pos = p * static_cast<float>(len);
    int idx = static_cast<int>(pos);
    float sFrac = pos - static_cast<float>(idx);
    if (idx < 0) {
        idx = 0;
        sFrac = 0.0f;
    }
    idx %= len;
    const int idxNext = (idx + 1) % len;

    const float* a = frameData(m, frameA);
    const float* b = frameData(m, frameB);
    const float sA = a[idx] + sFrac * (a[idxNext] - a[idx]);
    if (frameA == frameB || frameFrac <= 0.0f) {
        return sA;
    }
    const float sB = b[idx] + sFrac * (b[idxNext] - b[idx]);
    return sA + frameFrac * (sB - sA);
}

float SubtractiveMorphTable::lookup(float shape,
                                   float phaseRadians,
                                   float rootHz,
                                   float sampleRate) const noexcept {
    return lookupMip(shape, phaseRadians, pickMip(rootHz, sampleRate));
}

} // namespace audioapp
