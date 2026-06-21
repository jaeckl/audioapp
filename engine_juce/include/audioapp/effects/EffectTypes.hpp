#pragma once

#include <string_view>

namespace audioapp {

enum class EffectType {
    delay,
    reverb,
    chorus,
    phaser,
};

inline std::string_view toString(EffectType type) {
    switch (type) {
        case EffectType::delay:  return "delay";
        case EffectType::reverb: return "reverb";
        case EffectType::chorus: return "chorus";
        case EffectType::phaser: return "phaser";
    }
    return {};
}

inline EffectType effectTypeFromString(std::string_view s) {
    if (s == "delay")   return EffectType::delay;
    if (s == "reverb")  return EffectType::reverb;
    if (s == "chorus")  return EffectType::chorus;
    if (s == "phaser")  return EffectType::phaser;
    // Default fallback – callers should validate beforehand.
    return EffectType::delay;
}

} // namespace audioapp
