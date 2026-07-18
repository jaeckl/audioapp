#pragma once

#include <cstdint>

namespace audioapp {

/// Encoding mode for an LR/Mid-Side split container device.
enum class SplitMode : uint8_t { Lr = 0, MidSide = 1 };

} // namespace audioapp
