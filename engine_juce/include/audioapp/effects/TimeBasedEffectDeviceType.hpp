#pragma once

#include "audioapp/devices/IDeviceType.hpp"
#include <juce_core/juce_core.h>

namespace audioapp {

/**
    Base class for all time‑based effect device types (delay, reverb, chorus, phaser).
    It provides default (mostly no‑op) implementations for the IDeviceType interface
    so that concrete effect types can inherit without re‑implementing every method.
*/
class TimeBasedEffectDeviceType : public IDeviceType {
public:
    // IDeviceType pure virtuals that concrete subclasses must implement:
    // typeId – a unique string identifier for the effect type.
    // The rest have default implementations provided below.
    std::string typeId() const override = 0;

    // Default implementations – they can be overridden by concrete types if needed.
    DeviceSlot createDefault(const std::string& deviceId) const override {
        DeviceSlot slot;
        slot.id = deviceId;
        slot.config.typeId = typeId();     // Set by concrete subclass call
        slot.config.inputPanel = EmptyPanel{};
        slot.config.outputPanel = StereoOutputPanel{};
        slot.config.bypassed = false;
        return slot;
    }

    DeviceParameterResult setParameter(DeviceSlot&, std::string_view, float) const override {
        // No parameters for the abstract base – concrete types should override.
        return {};
    }

    bool setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const override {
        return false;
    }

    std::vector<std::string_view> modulatableParams() const override {
        return {};
    }

    void buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&, DeviceNodePlayback&) const override {
        // Concrete effect types should override.
    }

    bool buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const override {
        return false;
    }

    DeviceProcessor* createProcessor(ProcessorArena& arena) const override = 0;

    // Optional JSON helpers – default to empty.
    juce::var slotToVar(const DeviceSlot& slot) const override {
        juce::ignoreUnused(slot);
        return {};
    }

    DeviceSlot varToSlot(const juce::var& obj) const override {
        juce::ignoreUnused(obj);
        return {};
    }
};

} // namespace audioapp