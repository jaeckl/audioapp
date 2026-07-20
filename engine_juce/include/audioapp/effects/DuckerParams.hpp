#pragma once

#include <algorithm>
#include <memory>
#include <string>

namespace audioapp {

struct ChainPlayback;

struct DuckerParams {
    float duckThreshold = 0.45f;
    float duckDepth = 0.75f;
    float duckAttack = 0.15f;
    float duckRelease = 0.45f;
    float inputGain = 1.0f;
    float sidechainGain = 1.0f;
    /// Nested FX applied to the sidechain key before envelope detect.
    std::shared_ptr<const ChainPlayback> sidechainFx;
};

struct DuckerModel {
    std::string sidechainSourceId;
    float duckThreshold = 0.45f;
    float duckDepth = 0.75f;
    float duckAttack = 0.15f;
    float duckRelease = 0.45f;
    float sidechainGain = 1.0f;

    DuckerParams toPlaybackParams() const noexcept {
        DuckerParams p;
        p.duckThreshold = std::clamp(duckThreshold, 0.0f, 1.0f);
        p.duckDepth = std::clamp(duckDepth, 0.0f, 1.0f);
        p.duckAttack = std::clamp(duckAttack, 0.0f, 1.0f);
        p.duckRelease = std::clamp(duckRelease, 0.0f, 1.0f);
        p.sidechainGain = std::clamp(sidechainGain, 0.0f, 1.0f);
        return p;
    }
};

} // namespace audioapp
