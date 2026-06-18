#pragma once

#include "audioapp/ClapGenerator.hpp"

namespace audioapp {

struct ClapGeneratorInstance {
    float clapBursts = 0.50f;
    float clapSpread = 0.45f;
    float clapTone = 0.55f;
    float clapRoom = 0.50f;
    float clapDecay = 0.50f;

    ClapGeneratorParams toPlaybackParams(float gain) const {
        ClapGeneratorParams params;
        params.gain = gain;
        params.clapBursts = clapBursts;
        params.clapSpread = clapSpread;
        params.clapTone = clapTone;
        params.clapRoom = clapRoom;
        params.clapDecay = clapDecay;
        return params;
    }
};

} // namespace audioapp
