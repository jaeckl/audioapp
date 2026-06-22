// ChorusDeviceType implementation
#include "audioapp/effects/ChorusDeviceType.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/ChorusParams.hpp"
#include "juce_dsp/juce_dsp.h"

namespace audioapp {

DeviceSlot ChorusDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    ChorusParams instance;
    instance.depth = 0.25;
    instance.rateHz = 1.5;
    instance.mix = 0.4;
    instance.centreDelayMs = 7.0;
    instance.feedback = 0.0;
    slot.instance = std::move(instance);
    return slot;
}

DeviceParameterResult ChorusDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ChorusParams>(slot.instance);
    if (parameterId == "depth") {
        instance.depth = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "rateHz") {
        instance.rateHz = juce::jlimit(0.1, 5.0, static_cast<double>(value));
    } else if (parameterId == "mix") {
        instance.mix = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "centreDelayMs") {
        instance.centreDelayMs = juce::jlimit(0.0, 20.0, static_cast<double>(value));
    } else if (parameterId == "feedback") {
        instance.feedback = juce::jlimit(0.0, 0.95, static_cast<double>(value));
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

void ChorusDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Chorus;
    const auto& inst = std::get<ChorusParams>(slot.instance);
    ChorusParamsPlayback p;
    p.depth = static_cast<float>(inst.depth);
    p.rateHz = static_cast<float>(inst.rateHz);
    p.mix = static_cast<float>(inst.mix);
    p.centreDelayMs = static_cast<float>(inst.centreDelayMs);
    p.feedback = static_cast<float>(inst.feedback);
    p.inputGain = 1.0f;
    out.params = p;
}

bool ChorusDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var ChorusDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ChorusParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("depth", inst.depth);
    parameters->setProperty("rateHz", inst.rateHz);
    parameters->setProperty("mix", inst.mix);
    parameters->setProperty("centreDelayMs", inst.centreDelayMs);
    parameters->setProperty("feedback", inst.feedback);

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
            ChorusParams inst;
            inst.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.rateHz = p->getProperty("rateHz").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.centreDelayMs = p->getProperty("centreDelayMs").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.clamp();
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp