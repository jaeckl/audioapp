#pragma once

#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

struct LimiterInstance {
    float limitCeiling = 0.85f;
    float limitRelease = 0.40f;
    float limitDrive = 0.0f;

    LimiterParams toPlaybackParams() const {
        LimiterParams params;
        params.gain = 1.0f;
        params.limitCeiling = limitCeiling;
        params.limitRelease = limitRelease;
        params.limitDrive = limitDrive;
        return params;
    }
};

} // namespace audioapp
