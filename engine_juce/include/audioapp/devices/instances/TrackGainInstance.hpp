#pragma once

#include "audioapp/DeviceState.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

namespace audioapp {

struct TrackGainInstance {
    float gain = 1.0f;

    static TrackGainInstance fromState(const DeviceState& state) {
        TrackGainInstance instance;
        instance.gain = state.gain;
        return instance;
    }

    void applyTo(DeviceState& state) const {
        state.type = device_types::kTrackGain;
        state.gain = gain;
    }
};

} // namespace audioapp
