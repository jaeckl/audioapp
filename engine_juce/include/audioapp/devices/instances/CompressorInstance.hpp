#pragma once

#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

struct CompressorInstance {
    float compThreshold = 0.55f;
    float compRatio = 0.50f;
    float compAttack = 0.20f;
    float compRelease = 0.55f;
    float compKnee = 0.25f;
    float compMakeup = 0.35f;

    CompressorParams toPlaybackParams() const {
        CompressorParams params;
        params.gain = 1.0f;
        params.compThreshold = compThreshold;
        params.compRatio = compRatio;
        params.compAttack = compAttack;
        params.compRelease = compRelease;
        params.compKnee = compKnee;
        params.compMakeup = compMakeup;
        return params;
    }
};

} // namespace audioapp
