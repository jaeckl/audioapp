#include "audioapp/devices/TrackGainDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

#include <juce_core/juce_core.h>
#include <algorithm>

namespace audioapp {
namespace {

DeviceState stripSnapshot(const DeviceSlot& slot, std::string_view typeId) {
    DeviceState state;
    state.id = slot.id;
    state.type = std::string(typeId);
    state.gain = slot.gain;
    state.pan = slot.pan;
    state.bypassed = slot.bypassed;
    return state;
}

} // namespace

std::string TrackGainDeviceType::typeId() const {
    return device_types::kTrackGain;
}

DeviceSlot TrackGainDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = TrackGainInstance{};
    return slot;
}

DeviceState TrackGainDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    return stripSnapshot(slot, device_types::kTrackGain);
}

DeviceSlot TrackGainDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = TrackGainInstance{};
    return slot;
}

juce::var TrackGainDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    parameters->setProperty("gain", static_cast<double>(slot.gain));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot TrackGainDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            slot.gain = readFloat("gain", 1.0f);
            slot.pan = readFloat("pan", 0.5f);
            slot.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
        }
        slot.instance = TrackGainInstance{};
    }
    return slot;
}

DeviceParameterResult TrackGainDeviceType::setParameter(DeviceSlot& slot,
                                                        std::string_view parameterId,
                                                        float value) const {
    DeviceParameterResult result;
    if (parameterId != "gain") {
        return result;
    }
    slot.gain = std::clamp(value, 0.0f, 1.0f);
    result.handled = true;
    return result;
}

bool TrackGainDeviceType::setStringParameter(DeviceSlot&,
                                             std::string_view,
                                             const std::string&,
                                             const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> TrackGainDeviceType::modulatableParams() const {
    return {"gain"};
}

void TrackGainDeviceType::buildPlaybackNode(const DeviceSlot&,
                                            const PlaybackBuildContext&,
                                            DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::TrackGain;
    out.params = TrackGainParams{};
}

bool TrackGainDeviceType::buildLiveInstrument(const DeviceSlot&,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
