// ChorusDeviceType implementation
#include "audioapp/effects/ChorusDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/instances/EffectInstance.hpp"
#include "juce_dsp/juce_dsp.h"

namespace audioapp {

DeviceSlot ChorusDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    ChorusInstance instance;
    instance.params.depth = 0.25;
    instance.params.rateHz = 1.5;
    instance.params.mix = 0.4;
    instance.params.centreDelayMs = 7.0;
    instance.params.feedback = 0.0;
    slot.instance = std::move(instance);
    return slot;
}

DeviceParameterResult ChorusDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    auto& instance = std::get<ChorusInstance>(slot.instance);
    if (parameterId == "depth") {
        instance.params.depth = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "rateHz") {
        instance.params.rateHz = juce::jlimit(0.1, 5.0, static_cast<double>(value));
    } else if (parameterId == "mix") {
        instance.params.mix = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "centreDelayMs") {
        instance.params.centreDelayMs = juce::jlimit(0.0, 20.0, static_cast<double>(value));
    } else if (parameterId == "feedback") {
        instance.params.feedback = juce::jlimit(0.0, 0.95, static_cast<double>(value));
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool ChorusDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ChorusDeviceType::modulatableParams() const {
    return {"gain", "pan", "depth", "rateHz", "mix", "centreDelayMs", "feedback"};
}

void ChorusDeviceType::buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Unknown;
}

bool ChorusDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var ChorusDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ChorusInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("depth", inst.params.depth);
    parameters->setProperty("rateHz", inst.params.rateHz);
    parameters->setProperty("mix", inst.params.mix);
    parameters->setProperty("centreDelayMs", inst.params.centreDelayMs);
    parameters->setProperty("feedback", inst.params.feedback);

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

DeviceSlot ChorusDeviceType::varToSlot(const juce::var& obj) const {
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
            ChorusInstance inst;
            inst.params.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.params.rateHz = p->getProperty("rateHz").toString().getDoubleValue();
            inst.params.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.params.centreDelayMs = p->getProperty("centreDelayMs").toString().getDoubleValue();
            inst.params.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.params.clamp();
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp