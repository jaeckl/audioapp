#pragma once

#include "audioapp/KickGenerator.hpp"

namespace audioapp {

struct KickGeneratorInstance {
    float kickModel = 0.0f;
    float kickPitch = 0.55f;
    float kickPunch = 0.60f;
    float kickDecay = 0.50f;
    float kickClick = 0.35f;
    float kickTone = 0.50f;
    float kickVelocity = 1.0f;

    KickGeneratorParams toPlaybackParams(float gain) const {
        KickGeneratorParams params;
        params.gain = gain;
        params.kickModel = kickModel;
        params.kickPitch = kickPitch;
        params.kickPunch = kickPunch;
        params.kickDecay = kickDecay;
        params.kickClick = kickClick;
        params.kickTone = kickTone;
        params.kickVelocity = kickVelocity;
        return params;
    }
};

} // namespace audioapp
