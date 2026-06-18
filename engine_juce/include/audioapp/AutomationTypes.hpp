#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace audioapp {

struct AutomationPointPlayback {
    float beat = 0.0f;
    float value = 0.0f;
};

struct AutomationClipPlayback {
    char deviceId[48]{};
    char paramId[48]{};
    float clipStartBeat = 0.0f;
    float clipLengthBeats = 4.0f;
    int pointCount = 0;
    AutomationPointPlayback points[32]{};
};

struct AutomationPointState {
    double beat = 0.0;
    float value = 0.0f;
};

struct AutomationClipState {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    std::string deviceId;
    std::string paramId;
    std::vector<AutomationPointState> points;
};

} // namespace audioapp
