#pragma once

#include "audioapp/devices/DeviceRegistry.hpp"

namespace audioapp {

// Registers all time‑based effect device types (delay, reverb, chorus, phaser).
// This helper lives in the WP‑3 package so it does not require modification of
// existing DeviceRegistry.cpp.
void registerTimeBasedEffects(DeviceRegistry& registry);

} // namespace audioapp