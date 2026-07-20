#pragma once

#include <algorithm>

namespace audioapp {

struct UtilityParams {
    /// 0 = mono sum, 1 = full stereo (mid/side width).
    float utilWidth = 1.0f;
    float utilInvertL = 0.0f;
    float utilInvertR = 0.0f;
    float utilSwap = 0.0f;
    float utilTrim = 1.0f;
    float utilAutopan = 0.0f;
    float utilAutopanRate = 0.35f;
    float utilAutopanDepth = 0.5f;
};

struct UtilityModel {
    float utilWidth = 1.0f;
    float utilInvertL = 0.0f;
    float utilInvertR = 0.0f;
    float utilSwap = 0.0f;
    float utilTrim = 1.0f;
    float utilAutopan = 0.0f;
    float utilAutopanRate = 0.35f;
    float utilAutopanDepth = 0.5f;

    UtilityParams toPlaybackParams() const noexcept {
        return {
            std::clamp(utilWidth, 0.0f, 1.0f),
            utilInvertL >= 0.5f ? 1.0f : 0.0f,
            utilInvertR >= 0.5f ? 1.0f : 0.0f,
            utilSwap >= 0.5f ? 1.0f : 0.0f,
            std::clamp(utilTrim, 0.0f, 1.0f),
            utilAutopan >= 0.5f ? 1.0f : 0.0f,
            std::clamp(utilAutopanRate, 0.0f, 1.0f),
            std::clamp(utilAutopanDepth, 0.0f, 1.0f),
        };
    }
};

} // namespace audioapp
