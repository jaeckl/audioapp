#pragma once

#include "audioapp/DeviceState.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

namespace audioapp {

struct OscillatorInstance {
    float frequencyHz = 440.0f;

    static OscillatorInstance fromState(const DeviceState& state) {
        OscillatorInstance instance;
        instance.frequencyHz = state.frequencyHz;
        return instance;
    }

    void applyTo(DeviceState& state) const {
        state.type = device_types::kOscillator;
        state.frequencyHz = frequencyHz;
    }
};

} // namespace audioapp
