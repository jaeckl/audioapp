#pragma once

#include "audioapp/DeviceState.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <algorithm>
#include <string_view>

namespace audioapp::device_strip {

inline bool setGain(DeviceState& state, float value) {
    state.gain = std::clamp(value, 0.0f, 1.0f);
    return true;
}

inline bool setPan(DeviceState& state, float value) {
    if (state.type == device_types::kTrackGain) {
        return false;
    }
    state.pan = std::clamp(value, 0.0f, 1.0f);
    return true;
}

inline bool setBypass(DeviceState& state, float value) {
    if (state.type == device_types::kTrackGain) {
        return false;
    }
    state.bypassed = value >= 0.5f;
    return true;
}

inline bool setStripParameter(DeviceState& state, std::string_view parameterId, float value) {
    if (parameterId == "gain") {
        return setGain(state, value);
    }
    if (parameterId == "pan") {
        return setPan(state, value);
    }
    if (parameterId == "bypass") {
        return setBypass(state, value);
    }
    return false;
}

} // namespace audioapp::device_strip
