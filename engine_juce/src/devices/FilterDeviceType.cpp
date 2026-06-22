#include "audioapp/devices/FilterDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/FrequencyFxInstance.hpp"

#include <algorithm>
#include <cstring>
#include <juce_core/juce_core.h>

namespace audioapp {

std::string FilterDeviceType::typeId() const { return device_types::kFilter; }

DeviceSlot FilterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = FilterInstance{};
    return slot;
}


DeviceParameterResult FilterDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<FilterInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "ffxCutoff") {
        instance.ffxCutoff = clamped;
    } else if (parameterId == "ffxResonance") {
        instance.ffxResonance = clamped;
    } else if (parameterId == "ffxFilterMode") {
        instance.ffxFilterMode = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool FilterDeviceType::setStringParameter(DeviceSlot&,
                                          std::string_view,
                                          const std::string&,
                                          const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> FilterDeviceType::modulatableParams() const {
    return {"gain", "pan", "ffxCutoff", "ffxResonance", "ffxFilterMode"};
}

void FilterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                         const PlaybackBuildContext&,
                                         DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Filter;
    out.params = std::get<FilterInstance>(slot.instance).toPlaybackParams();
}

bool FilterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                           const PlaybackBuildContext&,
                                           LiveInstrumentSnapshot&) const {
    return false;
}

juce::var FilterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<FilterInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("ffxCutoff", static_cast<double>(inst.ffxCutoff));
    parameters->setProperty("ffxResonance", static_cast<double>(inst.ffxResonance));
    parameters->setProperty("ffxFilterMode", static_cast<double>(inst.ffxFilterMode));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot FilterDeviceType::varToSlot(const juce::var& obj) const {
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
            FilterInstance inst;
            inst.ffxCutoff = readFloat("ffxCutoff", 0.6f);
            inst.ffxResonance = readFloat("ffxResonance", 0.3f);
            inst.ffxFilterMode = readFloat("ffxFilterMode", 0.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp