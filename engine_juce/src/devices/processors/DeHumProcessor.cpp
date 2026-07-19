#include "audioapp/devices/processors/DeHumProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>
#include <algorithm>

namespace audioapp {

namespace {
struct Biquad {
    float b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
    float x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    float process(float x) noexcept {
        const float y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
        x2 = x1; x1 = x; y2 = y1; y1 = y;
        return y;
    }
};
} // namespace

void DeHumProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<DeHumParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float mains = p.mainsFreq >= 0.5f ? 60.0f : 50.0f;
    const float depth = std::clamp(p.depth, 0.0f, 1.0f);
    const int nHarm = 1 + static_cast<int>(std::clamp(p.harmonics, 0.0f, 1.0f) * 7.0f);
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));

    Biquad L[8], R[8];
    for (int h = 0; h < nHarm && h < 8; ++h) {
        const float hz = mains * static_cast<float>(h + 1);
        if (hz > sr * 0.45f) break;
        const float w = 2.0f * 3.14159265f * hz / sr;
        const float bw = 2.0f + depth * 8.0f;
        const float alpha = std::sin(w) / (2.0f * bw);
        const float cosw = std::cos(w);
        const float a0 = 1.0f + alpha;
        L[h].b0 = R[h].b0 = 1.0f / a0;
        L[h].b1 = R[h].b1 = (-2.0f * cosw) / a0;
        L[h].b2 = R[h].b2 = 1.0f / a0;
        L[h].a1 = R[h].a1 = (-2.0f * cosw) / a0;
        L[h].a2 = R[h].a2 = (1.0f - alpha) / a0;
        // restore filter memory from processor slots
        L[h].x1 = z1L_[h]; L[h].x2 = z2L_[h];
        R[h].x1 = z1R_[h]; R[h].x2 = z2R_[h];
    }

    for (int i = 0; i < block.numSamples; ++i) {
        float l = block.channelL[i];
        float r = block.channelR[i];
        for (int h = 0; h < nHarm && h < 8; ++h) {
            const float hz = mains * static_cast<float>(h + 1);
            if (hz > sr * 0.45f) break;
            const float nl = L[h].process(l);
            const float nr = R[h].process(r);
            l = l + (nl - l) * depth;
            r = r + (nr - r) * depth;
        }
        block.channelL[i] = l;
        block.channelR[i] = r;
    }

    for (int h = 0; h < nHarm && h < 8; ++h) {
        z1L_[h] = L[h].x1; z2L_[h] = L[h].x2;
        z1R_[h] = R[h].x1; z2R_[h] = R[h].x2;
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
