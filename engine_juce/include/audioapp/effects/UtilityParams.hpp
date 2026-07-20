#pragma once

#include <algorithm>

namespace audioapp {

struct UtilityParams {
    float utilMono = 0.0f;
    float utilPolarity = 0.0f; // 0 off, 0.33 L, 0.66 R, 1 both
    float utilSwap = 0.0f;
    float utilTrim = 1.0f;
    float utilAutopan = 0.0f;
    float utilAutopanRate = 0.35f;
    float utilAutopanDepth = 0.5f;
};

struct UtilityModel {
    float utilMono = 0.0f;
    float utilPolarity = 0.0f;
    float utilSwap = 0.0f;
    float utilTrim = 1.0f;
    float utilAutopan = 0.0f;
    float utilAutopanRate = 0.35f;
    float utilAutopanDepth = 0.5f;

    UtilityParams toPlaybackParams() const noexcept {
        return {
            utilMono >= 0.5f ? 1.0f : 0.0f,
            std::clamp(utilPolarity, 0.0f, 1.0f),
            utilSwap >= 0.5f ? 1.0f : 0.0f,
            std::clamp(utilTrim, 0.0f, 1.0f),
            utilAutopan >= 0.5f ? 1.0f : 0.0f,
            std::clamp(utilAutopanRate, 0.0f, 1.0f),
            std::clamp(utilAutopanDepth, 0.0f, 1.0f),
        };
    }
};

} // namespace audioapp
