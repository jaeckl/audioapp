#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {

uint16_t IDeviceType::paramIdFromString(std::string_view) const noexcept {
    return 0;
}

std::string_view IDeviceType::paramIdToString(uint16_t) const noexcept {
    return "";
}

std::span<const ParamDescriptor> IDeviceType::paramDescriptors() const noexcept {
    return {};
}

bool IDeviceType::usesDspAutomationSubBlocks() const noexcept {
    return false;
}

} // namespace audioapp
