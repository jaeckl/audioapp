#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceState.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"

#include <string>
#include <string_view>
#include <vector>

namespace audioapp {

/// Control-thread device type descriptor. One instance per built-in device kind.
/// Audio-thread processing uses DeviceNodePlayback snapshots built from device state.
class IDeviceType {
public:
    virtual ~IDeviceType() = default;

    virtual std::string typeId() const = 0;

    virtual DeviceState createDefault(const std::string& deviceId) const = 0;

    virtual DeviceParameterResult setParameter(DeviceState& state,
                                               std::string_view parameterId,
                                               float value) const = 0;

    virtual bool setStringParameter(DeviceState& state,
                                    std::string_view parameterId,
                                    const std::string& value,
                                    const PlaybackBuildContext& context) const = 0;

    virtual std::vector<std::string_view> modulatableParams() const = 0;

    virtual void buildPlaybackNode(const DeviceState& state,
                                   const PlaybackBuildContext& context,
                                   DeviceNodePlayback& out) const = 0;

    virtual bool buildLiveInstrument(const DeviceState& state,
                                     const PlaybackBuildContext& context,
                                     LiveInstrumentSnapshot& out) const = 0;
};

} // namespace audioapp
