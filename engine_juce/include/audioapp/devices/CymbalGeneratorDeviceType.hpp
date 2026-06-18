#pragma once

#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {

class CymbalGeneratorDeviceType final : public IDeviceType {
public:
    std::string typeId() const override;
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceState toSnapshotState(const DeviceSlot& slot) const override;
    DeviceSlot slotFromSnapshot(const DeviceState& state) const override;
    DeviceParameterResult setParameter(DeviceSlot& slot,
                                       std::string_view parameterId,
                                       float value) const override;
    bool setStringParameter(DeviceSlot& slot,
                            std::string_view parameterId,
                            const std::string& value,
                            const PlaybackBuildContext& context) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot& slot,
                           const PlaybackBuildContext& context,
                           DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot& slot,
                             const PlaybackBuildContext& context,
                             LiveInstrumentSnapshot& out) const override;
};

} // namespace audioapp
