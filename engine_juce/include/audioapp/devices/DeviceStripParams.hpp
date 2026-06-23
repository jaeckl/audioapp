#pragma once

#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"

#include <algorithm>
#include <string_view>

namespace audioapp::device_strip {

inline bool isTrackGain(const DeviceSlot& slot) {
    return std::holds_alternative<TrackGainParams>(slot.config.instance);
}

inline bool setGain(DeviceSlot& slot, float value) {
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    std::visit([clamped](auto& panel) {
        using T = std::decay_t<decltype(panel)>;
        if constexpr (std::is_same_v<T, MonoOutputPanel> || std::is_same_v<T, StereoOutputPanel>) {
            panel.gain = clamped;
        }
    }, slot.config.outputPanel);
    return true;
}

inline bool setPan(DeviceSlot& slot, float value) {
    if (isTrackGain(slot)) {
        return false;
    }
    auto* panel = std::get_if<StereoOutputPanel>(&slot.config.outputPanel);
    if (panel) {
        panel->pan = std::clamp(value, 0.0f, 1.0f);
        return true;
    }
    return false; // MonoOutputPanel — no pan
}

inline bool setBypass(DeviceSlot& slot, float value) {
    if (isTrackGain(slot)) {
        return false;
    }
    slot.config.bypassed = value >= 0.5f;
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