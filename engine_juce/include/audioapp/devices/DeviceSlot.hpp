#pragma once

#include "audioapp/devices/instances/KickGeneratorInstance.hpp"
#include "audioapp/devices/instances/SnareGeneratorInstance.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/SamplerInstance.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

#include <string>
#include <variant>

namespace audioapp {

using DeviceInstance = std::variant<OscillatorInstance,
                                    SamplerInstance,
                                    TrackGainInstance,
                                    SubtractiveSynthInstance,
                                    KickGeneratorInstance,
                                    SnareGeneratorInstance>;

struct DeviceSlot {
    std::string id;
    float gain = 1.0f;
    float pan = 0.5f;
    bool bypassed = false;
    DeviceInstance instance;
};

} // namespace audioapp
