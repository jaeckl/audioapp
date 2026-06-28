#pragma once

#include <algorithm>

namespace audioapp {

struct MidiDelayParams {
    float mode = 0.0f;       // 0 = seconds, 1 = tempo-sync
    float seconds = 0.25f;   // 0..2 seconds
    float division = 0.5f;   // delay in beats (0.25=1/16, 0.5=1/8, 1=1/4...)
};

struct MidiDelayModel {
    float mode = 0.0f;
    float seconds = 0.25f;
    float division = 0.5f;

    MidiDelayParams toPlaybackParams() const noexcept {
        return {
            std::clamp(mode, 0.0f, 1.0f),
            std::clamp(seconds, 0.0f, 2.0f),
            std::clamp(division, 0.0625f, 4.0f),
        };
    }
};

} // namespace audioapp
