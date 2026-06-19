#pragma once

#include "audioapp/SnareGenerator.hpp"

namespace audioapp {

struct SnareGeneratorInstance {
    float snareModel = 0.0f;
    float snareBody = 0.55f;
    float snareTune = 0.50f;
    float snareSnares = 0.60f;
    float snareSnap = 0.40f;
    float snareDecay = 0.50f;
    float snareVelocity = 1.0f;

    SnareGeneratorParams toPlaybackParams(float gain) const {
        SnareGeneratorParams params;
        params.gain = gain;
        params.snareModel = snareModel;
        params.snareBody = snareBody;
        params.snareTune = snareTune;
        params.snareSnares = snareSnares;
        params.snareSnap = snareSnap;
        params.snareDecay = snareDecay;
        params.snareVelocity = snareVelocity;
        return params;
    }
};

} // namespace audioapp
