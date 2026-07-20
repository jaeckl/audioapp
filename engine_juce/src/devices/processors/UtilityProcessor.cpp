#include "audioapp/devices/processors/UtilityProcessor.hpp"
#include "audioapp/effects/UtilityParams.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

void UtilityProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    const auto p = std::get<UtilityParams>(*ctx.modulatedParams);
    const int n = block.numSamples;
    if (n <= 0 || block.channelL == nullptr || block.channelR == nullptr) {
        return;
    }

    const float trim = std::clamp(p.utilTrim, 0.0f, 1.0f);
    const bool mono = p.utilMono >= 0.5f;
    const bool swap = p.utilSwap >= 0.5f;
    const float pol = std::clamp(p.utilPolarity, 0.0f, 1.0f);
    const bool invertL = (pol > 0.16f && pol < 0.5f) || pol >= 0.83f;
    const bool invertR = pol >= 0.5f;
    const bool autopan = p.utilAutopan >= 0.5f;
    const float rateHz = 0.1f + std::clamp(p.utilAutopanRate, 0.0f, 1.0f) * 7.9f;
    const float depth = std::clamp(p.utilAutopanDepth, 0.0f, 1.0f);
    const float phaseInc =
        ctx.sampleRate > 0.0 ? static_cast<float>(rateHz / ctx.sampleRate) : 0.0f;

    for (int i = 0; i < n; ++i) {
        float l = block.channelL[i];
        float r = block.channelR[i];
        if (mono) {
            const float m = 0.5f * (l + r);
            l = m;
            r = m;
        }
        if (swap) {
            const float t = l;
            l = r;
            r = t;
        }
        if (invertL) {
            l = -l;
        }
        if (invertR) {
            r = -r;
        }
        if (autopan) {
            const float pan = 0.5f + 0.5f * depth * std::sin(phase_ * 6.28318530718f);
            phase_ += phaseInc;
            if (phase_ >= 1.0f) {
                phase_ -= 1.0f;
            }
            const float gainL = std::cos(pan * 1.57079632679f);
            const float gainR = std::sin(pan * 1.57079632679f);
            l *= gainL;
            r *= gainR;
        }
        block.channelL[i] = l * trim;
        block.channelR[i] = r * trim;
    }
}

} // namespace audioapp
