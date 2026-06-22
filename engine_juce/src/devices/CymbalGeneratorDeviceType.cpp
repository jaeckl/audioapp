#include "audioapp/devices/CymbalGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/CymbalGenerator.hpp"

namespace audioapp {

std::string CymbalGeneratorDeviceType::typeId() const {
    return device_types::kCymbalGenerator;
}

DeviceSlot CymbalGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = CymbalGeneratorParams{};
    return slot;
}


DeviceParameterResult CymbalGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                              std::string_view parameterId,
                                                              float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<CymbalGeneratorParams>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "cymbalModel") {
        instance.cymbalModel = clamped;
    } else if (parameterId == "cymbalColor") {
        instance.cymbalColor = clamped;
    } else if (parameterId == "cymbalDecay") {
        instance.cymbalDecay = clamped;
    } else if (parameterId == "cymbalWidth") {
        instance.cymbalWidth = clamped;
    } else if (parameterId == "cymbalVelocity") {
        instance.cymbalVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool CymbalGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                   std::string_view,
                                                   const std::string&,
                                                   const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CymbalGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "cymbalColor", "cymbalDecay", "cymbalWidth", "cymbalVelocity"};
}

void CymbalGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  DeviceNodePlayback& out) const {
    auto params = std::get<CymbalGeneratorParams>(slot.instance);
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::CymbalGenerator;
    out.params = params;
}

bool CymbalGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                    const PlaybackBuildContext&,
                                                    LiveInstrumentSnapshot& out) const {
    auto params = std::get<CymbalGeneratorParams>(slot.instance);
    params.gain = slot.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::CymbalGenerator;
    out.gain = slot.gain;
    out.cymbal = params;
    return true;
}

juce::var CymbalGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<CymbalGeneratorParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("cymbalModel", static_cast<double>(inst.cymbalModel));
    parameters->setProperty("cymbalColor", static_cast<double>(inst.cymbalColor));
    parameters->setProperty("cymbalDecay", static_cast<double>(inst.cymbalDecay));
    parameters->setProperty("cymbalWidth", static_cast<double>(inst.cymbalWidth));
    parameters->setProperty("cymbalVelocity", static_cast<double>(inst.cymbalVelocity));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot CymbalGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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
            CymbalGeneratorParams inst;
            inst.cymbalModel = readFloat("cymbalModel", 0.0f);
            if (p->hasProperty("cymbalColor")) {
                inst.cymbalColor = readFloat("cymbalColor", 0.68f);
            } else {
                const float metal = readFloat("cymbalMetal", 0.55f);
                const float bright = readFloat("cymbalBrightness", 0.60f);
                inst.cymbalColor = (metal + bright) * 0.5f;
            }
            inst.cymbalDecay = readFloat("cymbalDecay", 0.50f);
            inst.cymbalWidth = readFloat("cymbalWidth", 0.35f);
            inst.cymbalVelocity = readFloat("cymbalVelocity", 1.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
