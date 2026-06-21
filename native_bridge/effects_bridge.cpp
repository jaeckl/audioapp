// Implementation of the Flutter MethodChannel "engine/effect" handler.
// This file is owned by work package WP-5.

#include "audioapp/bridge/BridgeHost.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/effects/EffectDeviceRegistration.hpp"
#include "audioapp/ProjectJson.hpp" // for json helper functions and bridge response builders
#include <juce_core/juce_core.h>
#include <string>

namespace audioapp::bridge {

// Helper to generate a UUID string for a new effect device.
static std::string generateDeviceId() {
    return juce::Uuid().toString().toStdString();
}

// Handles effect‑related MethodChannel calls. Returns a JSON string compatible with the
// BridgeHost response format ("{\"ok\":true, ...}").
std::string handleEffectCommand(const std::string& method, const std::string& argumentsJson) {
    // Create a registry with all built‑in device types and ensure the time‑based effects are
    // available for this call.
    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    audioapp::registerTimeBasedEffects(registry);

    // ----- getEffectSnapshot -------------------------------------------------
    if (method == "getEffectSnapshot") {
        // Parameters: {trackId: int, deviceIndex: int}
        // For this stub implementation we ignore track handling and simply return an empty
        // snapshot JSON matching the contract.
        juce::var resultObj(new juce::DynamicObject());
        resultObj.getDynamicObject()->setProperty("type", juce::var());
        resultObj.getDynamicObject()->setProperty("params", juce::var());
        return juce::JSON::toString(resultObj).toStdString();
    }

    // ----- setEffectParameter ------------------------------------------------
    if (method == "setEffectParameter") {
        const auto trackId = jsonGetNumberArg(argumentsJson, "trackId", 0.0);
        const auto deviceIndex = static_cast<int>(jsonGetNumberArg(argumentsJson, "deviceIndex", -1.0));
        const auto paramName = jsonGetStringArg(argumentsJson, "paramName");
        const auto value = static_cast<float>(jsonGetNumberArg(argumentsJson, "value", 0.0));
        // Locate the slot – placeholder stub using the registry.
        (void)trackId; (void)deviceIndex; // suppress unused warnings.
        // In a full implementation we would retrieve the DeviceSlot and then call
        // registry.setParameter(slot, paramName, value).
        // Here we simply report success.
        return buildBridgeOkWithMessage("parameter_set");
    }

    // ----- enableEffect ------------------------------------------------------
    if (method == "enableEffect") {
        const auto trackId = jsonGetNumberArg(argumentsJson, "trackId", 0.0);
        const auto deviceIndex = static_cast<int>(jsonGetNumberArg(argumentsJson, "deviceIndex", -1.0));
        const auto enabled = jsonGetBoolArg(argumentsJson, "enabled", true);
        (void)trackId; (void)deviceIndex;
        // Stub: locate slot, get its type and set bypass flag.
        // Real code would use registry.findTypeForSlot and manipulate the device.
        return buildBridgeOkWithMessage(enabled ? "effect_enabled" : "effect_disabled");
    }

    // ----- addEffect ----------------------------------------------------------
    if (method == "addEffect") {
        const auto trackId = jsonGetNumberArg(argumentsJson, "trackId", 0.0);
        const auto effectType = jsonGetStringArg(argumentsJson, "effectType");
        const std::string deviceId = generateDeviceId();
        // The registry creates a default slot for the requested effect type.
        // The returned DeviceSlot contains an index we expose to the Flutter side.
        // For this stub we simply return a fabricated index.
        (void)trackId;
        auto slot = registry.createDefault(effectType, deviceId);
        // Assume the slot carries a stable index – we use the slot's internal index if
        // available; otherwise we return 0 as a placeholder.
        int deviceIndex = 0;
        // If the DeviceSlot exposes an index, use it. This is a best‑effort placeholder.
        // The actual implementation would query the track model.
        juce::var replyObj(new juce::DynamicObject());
        replyObj.setProperty("deviceIndex", deviceIndex, nullptr);
        return juce::JSON::toString(replyObj).toStdString();
    }

    // ----- removeEffect -------------------------------------------------------
    if (method == "removeEffect") {
        const auto trackId = jsonGetNumberArg(argumentsJson, "trackId", 0.0);
        const auto deviceIndex = static_cast<int>(jsonGetNumberArg(argumentsJson, "deviceIndex", -1.0));
        (void)trackId; (void)deviceIndex;
        // Stub implementation – always succeed.
        return buildBridgeOkWithMessage("effect_removed");
    }

    // Unknown method – delegate to generic error.
    return buildBridgeError("unknown_effect_method");
}

} // namespace audioapp::bridge
