#pragma once

#include "audioapp/CymbalGenerator.hpp"

namespace audioapp {

struct CymbalGeneratorInstance {
    float cymbalModel = 0.0f;
    float cymbalColor = 0.68f;
    float cymbalDecay = 0.50f;
    float cymbalWidth = 0.35f;
    float cymbalVelocity = 1.0f;

    CymbalGeneratorParams toPlaybackParams(float gain) const {
        CymbalGeneratorParams params;
        params.gain = gain;
        params.cymbalModel = cymbalModel;
        params.cymbalColor = cymbalColor;
        params.cymbalDecay = cymbalDecay;
        params.cymbalWidth = cymbalWidth;
        params.cymbalVelocity = cymbalVelocity;
        return params;
    }
};

} // namespace audioapp
