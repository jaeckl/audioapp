#include "audioapp/devices/CompressorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/DynamicsProcessor.hpp"

#include <algorithm>

namespace audioapp {

std::string CompressorDeviceType::typeId() const { return device_types::kCompressor; }

DeviceSlot CompressorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = CompressorParams{};
    return slot;
}


DeviceParameterResult CompressorDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<CompressorParams>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "compThreshold") {
        instance.compThreshold = clamped;
    } else if (parameterId == "compRatio") {
        instance.compRatio = clamped;
    } else if (parameterId == "compAttack") {
        instance.compAttack = clamped;
    } else if (parameterId == "compRelease") {
        instance.compRelease = clamped;
    } else if (parameterId == "compKnee") {
        instance.compKnee = clamped;
    } else if (parameterId == "compMakeup") {
        instance.compMakeup = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool CompressorDeviceType::setStringParameter(DeviceSlot&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CompressorDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "compThreshold", "compRatio", "compAttack", "compRelease", "compKnee",
            "compMakeup"};
}

void CompressorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    auto params = std::get<CompressorParams>(slot.instance);
    out.kind = DeviceNodeKind::Compressor;
    out.params = params;
}

bool CompressorDeviceType::buildLiveInstrument(const DeviceSlot&,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot&) const {
    return false;
}

juce::var CompressorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<CompressorParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("compThreshold", static_cast<double>(inst.compThreshold));
    parameters->setProperty("compRatio", static_cast<double>(inst.compRatio));
    parameters->setProperty("compAttack", static_cast<double>(inst.compAttack));
    parameters->setProperty("compRelease", static_cast<double>(inst.compRelease));
    parameters->setProperty("compKnee", static_cast<double>(inst.compKnee));
    parameters->setProperty("compMakeup", static_cast<double>(inst.compMakeup));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot CompressorDeviceType::varToSlot(const juce::var& obj) const {
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
            CompressorParams inst;
            inst.inputGain = readFloat("inputGain", 1.0f);
            inst.compThreshold = readFloat("compThreshold", 0.55f);
            inst.compRatio = readFloat("compRatio", 0.50f);
            inst.compAttack = readFloat("compAttack", 0.20f);
            inst.compRelease = readFloat("compRelease", 0.55f);
            inst.compKnee = readFloat("compKnee", 0.25f);
            inst.compMakeup = readFloat("compMakeup", 0.35f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
