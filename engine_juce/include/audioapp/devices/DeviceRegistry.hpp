#pragma once

#include "audioapp/devices/IDeviceType.hpp"

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
    DeviceState createDefault(std::string_view typeId, const std::string& deviceId) const;

    static DeviceRegistry createBuiltIn();

private:
    std::vector<std::unique_ptr<IDeviceType>> types_;
    std::vector<std::string_view> typeIds_;
};

} // namespace audioapp
