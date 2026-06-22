#include "audioapp/devices/SnareGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/SnareGenerator.hpp"

namespace audioapp {

std::string SnareGeneratorDeviceType::typeId() const {
    return device_types::kSnareGenerator;
}

DeviceSlot SnareGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = SnareGeneratorParams{};
    return slot;
}


DeviceParameterResult SnareGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view parameterId,
                                                             float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<SnareGeneratorParams>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "snareModel") {
        instance.snareModel = clamped;
    } else if (parameterId == "snareBody") {
        instance.snareBody = clamped;
    } else if (parameterId == "snareRing") {
        instance.snareRing = clamped;
    } else if (parameterId == "snareTune") {
        instance.snareTune = clamped;
    } else if (parameterId == "snareSnares") {
        instance.snareSnares = clamped;
    } else if (parameterId == "snareSnap") {
        instance.snareSnap = clamped;
    } else if (parameterId == "snareDecay") {
        instance.snareDecay = clamped;
    } else if (parameterId == "snareVelocity") {
        instance.snareVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool SnareGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                  std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SnareGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "snareModel", "snareBody", "snareRing", "snareTune", "snareSnares",
            "snareSnap", "snareDecay", "snareVelocity"};
}

void SnareGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext&,
                                                 DeviceNodePlayback& out) const {
    auto params = std::get<SnareGeneratorParams>(slot.instance);
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::SnareGenerator;
    out.params = params;
}

bool SnareGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot& out) const {
    auto params = std::get<SnareGeneratorParams>(slot.instance);
    params.gain = slot.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::SnareGenerator;
    out.gain = slot.gain;
    out.snare = params;
    return true;
}

juce::var SnareGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<SnareGeneratorParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("snareModel", static_cast<double>(inst.snareModel));
    parameters->setProperty("snareBody", static_cast<double>(inst.snareBody));
    parameters->setProperty("snareRing", static_cast<double>(inst.snareRing));
    parameters->setProperty("snareTune", static_cast<double>(inst.snareTune));
    parameters->setProperty("snareSnares", static_cast<double>(inst.snareSnares));
    parameters->setProperty("snareSnap", static_cast<double>(inst.snareSnap));
    parameters->setProperty("snareDecay", static_cast<double>(inst.snareDecay));
    parameters->setProperty("snareVelocity", static_cast<double>(inst.snareVelocity));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot SnareGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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
            SnareGeneratorParams inst;
            inst.snareModel = readFloat("snareModel", 0.0f);
            inst.snareBody = readFloat("snareBody", 0.45f);
            inst.snareRing = readFloat("snareRing", 0.40f);
            inst.snareTune = readFloat("snareTune", 0.50f);
            inst.snareSnares = readFloat("snareSnares", 0.60f);
            inst.snareSnap = readFloat("snareSnap", 0.40f);
            inst.snareDecay = readFloat("snareDecay", 0.50f);
            inst.snareVelocity = readFloat("snareVelocity", 1.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
