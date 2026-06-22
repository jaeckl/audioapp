#include "audioapp/devices/GateDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/DynamicsProcessor.hpp"

#include <algorithm>

namespace audioapp {

std::string GateDeviceType::typeId() const { return device_types::kGate; }

DeviceSlot GateDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = GateParams{};
    return slot;
}


DeviceParameterResult GateDeviceType::setParameter(DeviceSlot& slot,
                                                   std::string_view parameterId,
                                                   float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<GateParams>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "gateThreshold") {
        instance.gateThreshold = clamped;
    } else if (parameterId == "gateAttack") {
        instance.gateAttack = clamped;
    } else if (parameterId == "gateRelease") {
        instance.gateRelease = clamped;
    } else if (parameterId == "gateHold") {
        instance.gateHold = clamped;
    } else if (parameterId == "gateRange") {
        instance.gateRange = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool GateDeviceType::setStringParameter(DeviceSlot&,
                                        std::string_view,
                                        const std::string&,
                                        const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> GateDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "gateThreshold", "gateAttack", "gateRelease", "gateHold", "gateRange"};
}

void GateDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                       const PlaybackBuildContext&,
                                       DeviceNodePlayback& out) const {
    auto params = std::get<GateParams>(slot.instance);
    out.kind = DeviceNodeKind::Gate;
    out.params = params;
}

bool GateDeviceType::buildLiveInstrument(const DeviceSlot&,
                                         const PlaybackBuildContext&,
                                         LiveInstrumentSnapshot&) const {
    return false;
}

juce::var GateDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<GateParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("gateThreshold", static_cast<double>(inst.gateThreshold));
    parameters->setProperty("gateAttack", static_cast<double>(inst.gateAttack));
    parameters->setProperty("gateRelease", static_cast<double>(inst.gateRelease));
    parameters->setProperty("gateHold", static_cast<double>(inst.gateHold));
    parameters->setProperty("gateRange", static_cast<double>(inst.gateRange));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));

    return juce::var(object);
}

DeviceSlot GateDeviceType::varToSlot(const juce::var& obj) const {
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
            GateParams inst;
            inst.inputGain = readFloat("inputGain", 1.0f);
            inst.gateThreshold = readFloat("gateThreshold", 0.45f);
            inst.gateAttack = readFloat("gateAttack", 0.25f);
            inst.gateRelease = readFloat("gateRelease", 0.50f);
            inst.gateHold = readFloat("gateHold", 0.20f);
            inst.gateRange = readFloat("gateRange", 0.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
