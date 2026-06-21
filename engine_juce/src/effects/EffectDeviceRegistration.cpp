#include "audioapp/effects/EffectDeviceRegistration.hpp"
#include "audioapp/effects/DelayDeviceType.hpp"
#include "audioapp/effects/ReverbDeviceType.hpp"
#include "audioapp/effects/ChorusDeviceType.hpp"
#include "audioapp/effects/PhaserDeviceType.hpp"

namespace audioapp {

void registerTimeBasedEffects(DeviceRegistry& registry) {
    registry.registerType(std::make_unique<DelayDeviceType>());
    registry.registerType(std::make_unique<ReverbDeviceType>());
    registry.registerType(std::make_unique<ChorusDeviceType>());
    registry.registerType(std::make_unique<PhaserDeviceType>());
}

} // namespace audioapp