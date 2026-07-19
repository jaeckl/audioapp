#include "audioapp/effects/RestoreEffectRegistration.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/effects/DcOffsetDeviceType.hpp"
#include "audioapp/effects/DeCracklerDeviceType.hpp"
#include "audioapp/effects/DeEsserDeviceType.hpp"
#include "audioapp/effects/DeHumDeviceType.hpp"
#include "audioapp/effects/DeNoiseDeviceType.hpp"

namespace audioapp {

void registerRestoreEffects(DeviceRegistry& registry) {
    registry.registerType(std::make_unique<DcOffsetDeviceType>());
    registry.registerType(std::make_unique<DeCracklerDeviceType>());
    registry.registerType(std::make_unique<DeEsserDeviceType>());
    registry.registerType(std::make_unique<DeHumDeviceType>());
    registry.registerType(std::make_unique<DeNoiseDeviceType>());
}

} // namespace audioapp
