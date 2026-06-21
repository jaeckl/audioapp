#pragma once

#include <string>
#include <variant>
#include <juce_core/juce_core.h>

#include "DelayParams.hpp"
#include "ReverbParams.hpp"
#include "ChorusParams.hpp"
#include "PhaserParams.hpp"

namespace audioapp {

/**
    Unified snapshot for any time‑based effect.
    The concrete parameter structs are held in a std::variant.
    The `type` string is a discriminator matching the effect type identifier.
*/
struct EffectSnapshot {
    // Discriminator – e.g. "delay", "reverb", etc.
    std::string type;

    // Variant holding concrete parameter struct.
    std::variant<std::monostate,
                 DelayParams,
                 ReverbParams,
                 ChorusParams,
                 PhaserParams> params;

    // Serialize to juce::var (JSON compatible).
    juce::var toJson() const;

    // Deserialize from juce::var.
    static EffectSnapshot fromJson(const juce::var& obj);
};

} // namespace audioapp
