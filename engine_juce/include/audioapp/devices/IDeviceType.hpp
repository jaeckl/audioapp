#pragma once

#include "audioapp/DeviceState.hpp"

#include <string>

namespace audioapp {

/// Control-thread device type descriptor. One instance per built-in device kind.
/// Audio-thread processing uses DeviceNodePlayback snapshots built from device state.
class IDeviceType {
public:
    virtual ~IDeviceType() = default;

    virtual std::string typeId() const = 0;

    /// Create a new device instance with type-specific defaults.
    virtual DeviceState createDefault(const std::string& deviceId) const = 0;
};

} // namespace audioapp
