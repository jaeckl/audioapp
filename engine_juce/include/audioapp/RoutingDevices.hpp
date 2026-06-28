#pragma once

#include <algorithm>
#include <cstdint>
#include <cmath>
#include <string>

namespace audioapp {

struct RoutingParams {
    float routeMix = 1.0f;
};

struct RoutingModel {
    std::string sourceId;
    float routeMix = 1.0f;

    RoutingParams toPlaybackParams() const noexcept {
        RoutingParams params;
        params.routeMix = std::clamp(routeMix, 0.0f, 1.0f);
        return params;
    }
};

} // namespace audioapp
