#pragma once

#include "audioapp/devices/DeviceSlot.hpp"

#include <algorithm>
#include <string_view>

namespace audioapp::device_strip {

inline bool isTrackGain(const DeviceSlot& slot) {
    return std::holds_alternative<TrackGainInstance>(slot.instance);
}

inline bool setGain(DeviceSlot& slot, float value) {
    slot.gain = std::clamp(value, 0.0f, 1.0f);
    return true;
}

inline bool setPan(DeviceSlot& slot, float value) {
    if (isTrackGain(slot)) {
        return false;
    }
    slot.pan = std::clamp(value, 0.0f, 1.0f);
    return true;
}

inline bool setBypass(DeviceSlot& slot, float value) {
    if (isTrackGain(slot)) {
        return false;
    }
    slot.bypassed = value >= 0.5f;
    return true;
}

inline bool setStripParameter(DeviceSlot& slot, std::string_view parameterId, float value) {
    if (parameterId == "gain") {
        return setGain(slot, value);
    }
    if (parameterId == "pan") {
        return setPan(slot, value);
    }
    if (parameterId == "bypass") {
        return setBypass(slot, value);
    }
    return false;
}

} // namespace audioapp::device_strip
