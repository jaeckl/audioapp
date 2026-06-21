#pragma once

#include "audioapp/effects/DelayParams.hpp"
#include "audioapp/effects/ReverbParams.hpp"
#include "audioapp/effects/ChorusParams.hpp"
#include "audioapp/effects/PhaserParams.hpp"

namespace audioapp {

struct DelayInstance { DelayParams params; };
struct ReverbInstance { ReverbParams params; };
struct ChorusInstance { ChorusParams params; };
struct PhaserInstance { PhaserParams params; };

} // namespace audioapp