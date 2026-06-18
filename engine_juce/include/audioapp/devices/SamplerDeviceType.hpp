#pragma once

#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {

class SamplerDeviceType final : public IDeviceType {
public:
    std::string typeId() const override;
    DeviceState createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceState& state,
                                       std::string_view parameterId,
                                       float value) const override;
    bool setStringParameter(DeviceState& state,
                            std::string_view parameterId,
                            const std::string& value,
                            const PlaybackBuildContext& context) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceState& state,
                           const PlaybackBuildContext& context,
                           DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceState& state,
                             const PlaybackBuildContext& context,
                             LiveInstrumentSnapshot& out) const override;
};

} // namespace audioapp
