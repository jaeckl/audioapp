#pragma once

#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

struct GateInstance {
    float gateThreshold = 0.45f;
    float gateAttack = 0.25f;
    float gateRelease = 0.50f;
    float gateHold = 0.20f;
    float gateRange = 0.0f;

    GateParams toPlaybackParams() const {
        GateParams params;
        params.gain = 1.0f;
        params.gateThreshold = gateThreshold;
        params.gateAttack = gateAttack;
        params.gateRelease = gateRelease;
        params.gateHold = gateHold;
        params.gateRange = gateRange;
        return params;
    }
};

} // namespace audioapp
