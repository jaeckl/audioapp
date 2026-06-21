#pragma once

#include "audioapp/devices/instances/KickGeneratorInstance.hpp"
#include "audioapp/devices/instances/SnareGeneratorInstance.hpp"
#include "audioapp/devices/instances/ClapGeneratorInstance.hpp"
#include "audioapp/devices/instances/CymbalGeneratorInstance.hpp"
#include "audioapp/devices/instances/CrashGeneratorInstance.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/SamplerInstance.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"
#include "audioapp/devices/instances/GateInstance.hpp"
#include "audioapp/devices/instances/CompressorInstance.hpp"
#include "audioapp/devices/instances/ExpanderInstance.hpp"
#include "audioapp/devices/instances/BassSynthInstance.hpp"
#include "audioapp/devices/instances/LimiterInstance.hpp"
#include "audioapp/devices/instances/EffectInstance.hpp"

#include <string>
#include <variant>

namespace audioapp {

using DeviceInstance = std::variant<OscillatorInstance,
                                    SamplerInstance,
                                    TrackGainInstance,
                                    SubtractiveSynthInstance,
                                    KickGeneratorInstance,
                                    SnareGeneratorInstance,
                                    ClapGeneratorInstance,
                                    CymbalGeneratorInstance,
                                    CrashGeneratorInstance,
                                    GateInstance,
                                    CompressorInstance,
                                    ExpanderInstance,
                                    LimiterInstance,
                                    BassSynthInstance,
                                    DelayInstance,
                                    ReverbInstance,
                                    ChorusInstance,
                                    PhaserInstance>;

struct DeviceSlot {
    std::string id;
    float gain = 1.0f;
    float pan = 0.5f;
    bool bypassed = false;
    DeviceInstance instance;
};

} // namespace audioapp
