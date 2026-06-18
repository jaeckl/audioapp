#pragma once

#include "audioapp/CymbalGenerator.hpp"

namespace audioapp {

struct CymbalGeneratorInstance {
    float cymbalMetal = 0.55f;
    float cymbalBrightness = 0.60f;
    float cymbalDecay = 0.50f;
    float cymbalChoke = 0.0f;
    float cymbalVelocity = 1.0f;

    CymbalGeneratorParams toPlaybackParams(float gain) const {
        CymbalGeneratorParams params;
        params.gain = gain;
        params.cymbalMetal = cymbalMetal;
        params.cymbalBrightness = cymbalBrightness;
        params.cymbalDecay = cymbalDecay;
        params.cymbalChoke = cymbalChoke;
        params.cymbalVelocity = cymbalVelocity;
        return params;
    }
};

} // namespace audioapp
