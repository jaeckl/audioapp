#include "audioapp/devices/FrequencyShifterDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"

#include <algorithm>
#include <cstring>
#include <juce_core/juce_core.h>

namespace audioapp {

std::string FrequencyShifterDeviceType::typeId() const {
    return device_types::kFrequencyShifter;
}

DeviceSlot FrequencyShifterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = FrequencyShifterModel{};
    return slot;
}


DeviceParameterResult FrequencyShifterDeviceType::setParameter(DeviceSlot& slot,
                                                               std::string_view parameterId,
                                                               float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<FrequencyShifterModel>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "ffxShift") {
        instance.ffxShift = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool FrequencyShifterDeviceType::setStringParameter(DeviceSlot&,
                                                    std::string_view,
                                                    const std::string&,
                                                    const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> FrequencyShifterDeviceType::modulatableParams() const {
    return {"gain", "pan", "ffxShift"};
}

void FrequencyShifterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::FrequencyShifter;
    out.params = std::get<FrequencyShifterModel>(slot.instance).toPlaybackParams();
}

bool FrequencyShifterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                                     const PlaybackBuildContext&,
                                                     LiveInstrumentSnapshot&) const {
    return false;
}

juce::var FrequencyShifterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<FrequencyShifterModel>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("ffxShift", static_cast<double>(inst.ffxShift));

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

DeviceSlot FrequencyShifterDeviceType::varToSlot(const juce::var& obj) const {
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
            FrequencyShifterModel inst;
            inst.ffxShift = readFloat("ffxShift", 0.5f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp