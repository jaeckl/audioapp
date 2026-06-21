// ReverbDeviceType implementation
#include "audioapp/effects/ReverbDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/instances/EffectInstance.hpp"
#include "juce_audio_processors/juce_audio_processors.h"

namespace audioapp {

DeviceSlot ReverbDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    ReverbInstance instance;
    instance.params.roomSize = 0.5;
    instance.params.damping = 0.5;
    instance.params.wetLevel = 0.33;
    instance.params.dryLevel = 0.7;
    instance.params.width = 1.0;
    instance.params.freezeMode = false;
    slot.instance = std::move(instance);
    return slot;
}

DeviceParameterResult ReverbDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    auto& instance = std::get<ReverbInstance>(slot.instance);
    if (parameterId == "roomSize") {
        instance.params.roomSize = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "damping") {
        instance.params.damping = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "wetLevel") {
        instance.params.wetLevel = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "dryLevel") {
        instance.params.dryLevel = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "width") {
        instance.params.width = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool ReverbDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ReverbDeviceType::modulatableParams() const {
    return {"gain", "pan", "roomSize", "damping", "wetLevel", "dryLevel", "width"};
}

void ReverbDeviceType::buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Unknown;
}

bool ReverbDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var ReverbDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ReverbInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("roomSize", inst.params.roomSize);
    parameters->setProperty("damping", inst.params.damping);
    parameters->setProperty("wetLevel", inst.params.wetLevel);
    parameters->setProperty("dryLevel", inst.params.dryLevel);
    parameters->setProperty("width", inst.params.width);
    parameters->setProperty("freezeMode", inst.params.freezeMode ? 1.0 : 0.0);

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

DeviceSlot ReverbDeviceType::varToSlot(const juce::var& obj) const {
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
            ReverbInstance inst;
            inst.params.roomSize = p->getProperty("roomSize").toString().getDoubleValue();
            inst.params.damping = p->getProperty("damping").toString().getDoubleValue();
            inst.params.wetLevel = p->getProperty("wetLevel").toString().getDoubleValue();
            inst.params.dryLevel = p->getProperty("dryLevel").toString().getDoubleValue();
            inst.params.width = p->getProperty("width").toString().getDoubleValue();
            inst.params.freezeMode = static_cast<bool>(p->getProperty("freezeMode"));
            inst.params.clamp();
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp