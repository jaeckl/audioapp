#include "audioapp/devices/processors/DeEsserProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>
#include <algorithm>

namespace audioapp {

void DeEsserProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {

    auto p = std::get<DeEsserParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float freq = 2000.0f + std::clamp(p.freq, 0.0f, 1.0f) * 10000.0f;
    const float thresh = std::clamp(p.threshold, 0.0f, 1.0f) * 0.4f;
    const float amount = std::clamp(p.amount, 0.0f, 1.0f);
    const bool listen = p.listen >= 0.5f;
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    const float w = 2.0f * 3.14159265f * freq / sr;
    const float cosw = std::cos(w);
    const float alpha = std::sin(w) * 0.5f;
    const float b0 = alpha, b1 = 0.0f, b2 = -alpha;
    const float a0 = 1.0f + alpha, a1 = -2.0f * cosw, a2 = 1.0f - alpha;
    const float invA0 = 1.0f / a0;
    for (int i = 0; i < block.numSamples; ++i) {
        const float inL = block.channelL[i];
        const float inR = block.channelR[i];
        const float bandL = (b0 * inL + b1 * z1L_[0] + b2 * z2L_[0] - a1 * z1L_[1] - a2 * z2L_[1]) * invA0;
        z2L_[0] = z1L_[0]; z1L_[0] = inL; z2L_[1] = z1L_[1]; z1L_[1] = bandL;
        const float bandR = (b0 * inR + b1 * z1R_[0] + b2 * z2R_[0] - a1 * z1R_[1] - a2 * z2R_[1]) * invA0;
        z2R_[0] = z1R_[0]; z1R_[0] = inR; z2R_[1] = z1R_[1]; z1R_[1] = bandR;
        const float envIn = 0.5f * (std::abs(bandL) + std::abs(bandR));
        stateC_ = stateC_ * 0.95f + envIn * 0.05f;
        float gr = 1.0f;
        if (stateC_ > thresh)
            gr = 1.0f - amount * std::min(1.0f, (stateC_ - thresh) / 0.3f);
        if (listen) {
            block.channelL[i] = bandL;
            block.channelR[i] = bandR;
        } else {
            block.channelL[i] = inL - bandL * (1.0f - gr);
            block.channelR[i] = inR - bandR * (1.0f - gr);
        }
    }

    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
