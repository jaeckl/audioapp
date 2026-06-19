#pragma once

#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

struct ExpanderInstance {
    float inputGain = 1.0f;
    float expandThreshold = 0.40f;
    float expandRatio = 0.45f;
    float expandAttack = 0.25f;
    float expandRelease = 0.55f;
    float expandRange = 0.15f;

    ExpanderParams toPlaybackParams() const {
        ExpanderParams params;
        params.gain = 1.0f;
        params.inputGain = inputGain;
        params.expandThreshold = expandThreshold;
        params.expandRatio = expandRatio;
        params.expandAttack = expandAttack;
        params.expandRelease = expandRelease;
        params.expandRange = expandRange;
        return params;
    }
};

} // namespace audioapp
