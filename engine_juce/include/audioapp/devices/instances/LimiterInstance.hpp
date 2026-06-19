#pragma once

#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

struct LimiterInstance {
    float inputGain = 1.0f;
    float limitCeiling = 0.85f;
    float limitAttack = 0.10f;
    float limitRelease = 0.40f;
    float limitKnee = 0.0f;
    float limitDrive = 0.0f;
    float limitMakeup = 0.0f;

    LimiterParams toPlaybackParams() const {
        LimiterParams params;
        params.gain = 1.0f;
        params.inputGain = inputGain;
        params.limitCeiling = limitCeiling;
        params.limitAttack = limitAttack;
        params.limitRelease = limitRelease;
        params.limitKnee = limitKnee;
        params.limitDrive = limitDrive;
        params.limitMakeup = limitMakeup;
        return params;
    }
};

} // namespace audioapp
