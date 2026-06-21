// Reverb effect device type implementation
#pragma once

#include "audioapp/devices/IDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/effects/ReverbParams.hpp"
#include "audioapp/effects/TimeBasedEffectDeviceType.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include <juce_core/juce_core.h>

namespace audioapp {

class ReverbDeviceType final : public TimeBasedEffectDeviceType {
public:
    std::string typeId() const override { return device_types::kReverb; }
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot& slot, std::string_view parameterId, float value) const override;
    bool setStringParameter(DeviceSlot& slot, std::string_view parameterId, const std::string& value, const PlaybackBuildContext& context) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext& context, DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot& slot, const PlaybackBuildContext& context, LiveInstrumentSnapshot& out) const override;
    juce::var slotToVar(const DeviceSlot& slot) const override;
    DeviceSlot varToSlot(const juce::var& obj) const override;
};

} // namespace audioapp
