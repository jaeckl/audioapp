#pragma once

#include "audioapp/devices/IDeviceType.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"

#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace audioapp {

class DeviceRegistry {
public:
    DeviceRegistry();

    void registerType(std::unique_ptr<IDeviceType> type);
    const IDeviceType* find(std::string_view typeId) const;
    bool isKnownType(std::string_view typeId) const;
    std::vector<std::string_view> knownTypes() const;

    DeviceSlot createDefault(std::string_view typeId, const std::string& deviceId) const;

    DeviceParameterResult setParameter(DeviceSlot& slot,
                                       std::string_view parameterId,
                                       float value) const;
    bool setStringParameter(DeviceSlot& slot,
                            std::string_view parameterId,
                            const std::string& value,
                            const PlaybackBuildContext& context) const;
    void buildPlaybackNode(const DeviceSlot& slot,
                           const PlaybackBuildContext& context,
                           DeviceNodePlayback& out) const;
    bool buildLiveInstrument(const DeviceSlot& slot,
                             const PlaybackBuildContext& context,
                             LiveInstrumentSnapshot& out) const;
    std::vector<std::string_view> modulatableParams(std::string_view typeId) const;

    /// Find the IDeviceType* that matches the given DeviceSlot's variant type.
    /// Returns nullptr if no matching type is registered.
    const IDeviceType* findTypeForSlot(const DeviceSlot& slot) const;

    static DeviceRegistry createBuiltIn();

private:
    std::vector<std::unique_ptr<IDeviceType>> types_;
    std::vector<std::string> typeIds_;
};

} // namespace audioapp
