#pragma once

#include "audioapp/CrashGenerator.hpp"

namespace audioapp {

struct CrashGeneratorInstance {
    float crashModel = 0.0f;
    float crashColor = 0.62f;
    float crashSpread = 0.50f;
    float crashDecay = 0.55f;
    float crashVelocity = 1.0f;

    CrashGeneratorParams toPlaybackParams(float gain) const {
        CrashGeneratorParams params;
        params.gain = gain;
        params.crashModel = crashModel;
        params.crashColor = crashColor;
        params.crashSpread = crashSpread;
        params.crashDecay = crashDecay;
        params.crashVelocity = crashVelocity;
        return params;
    }
};

} // namespace audioapp
