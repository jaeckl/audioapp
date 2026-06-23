#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <string>
#include <string_view>
#include <vector>

namespace audioapp {

/// Control-thread device type descriptor. One instance per built-in device kind.
/// Audio-thread processing uses DeviceNodePlayback snapshots built from device slots.
class IDeviceType {
public:
    virtual ~IDeviceType() = default;

    virtual std::string typeId() const = 0;

    virtual DeviceSlot createDefault(const std::string& deviceId) const = 0;

    virtual DeviceParameterResult setParameter(DeviceSlot& slot,
                                               std::string_view parameterId,
                                               float value) const = 0;

    virtual bool setStringParameter(DeviceSlot& slot,
                                    std::string_view parameterId,
                                    const std::string& value,
                                    const PlaybackBuildContext& context) const = 0;

    virtual std::vector<std::string_view> modulatableParams() const = 0;

    virtual void buildPlaybackNode(const DeviceSlot& slot,
                                   const PlaybackBuildContext& context,
                                   DeviceNodePlayback& out) const = 0;

    virtual bool buildLiveInstrument(const DeviceSlot& slot,
                                     const PlaybackBuildContext& context,
                                     LiveInstrumentSnapshot& out) const = 0;

    /// Create a DeviceProcessor in the given arena.
    /// Called on control thread only.
    virtual DeviceProcessor* createProcessor(ProcessorArena& arena) const = 0;

    /// Serialize a DeviceSlot to a juce::var suitable for JSON output.
    /// Default implementation returns an empty var (null), which triggers the
    /// fallback chain in ProjectJson.cpp.
    /// Concrete device types should override with proper serialization.
    /// Called on control thread only.
    /// Serialize a DeviceSlot to a juce::var suitable for JSON output.
    /// Default implementation triggers an assertion and returns empty,
    /// which causes the fallback chain in ProjectJson.cpp.
    /// Concrete device types MUST override with proper serialization.
    /// Called on control thread only.
    virtual juce::var slotToVar(const DeviceSlot& slot) const {
        juce::ignoreUnused(slot);
        jassertfalse;
        return {};
    }

    /// Deserialize a juce::var to a DeviceSlot.
    /// Default implementation triggers an assertion and returns empty,
    /// which causes the fallback chain in ProjectJson.cpp.
    /// Concrete device types MUST override with proper deserialization.
    /// Called on control thread only.
    virtual DeviceSlot varToSlot(const juce::var& obj) const {
        juce::ignoreUnused(obj);
        jassertfalse;
        return {};
    }
};

} // namespace audioapp
