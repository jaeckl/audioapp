// DelayDeviceType implementation
#include "audioapp/effects/DelayDeviceType.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/DelayParams.hpp"
#include "juce_dsp/juce_dsp.h"

namespace audioapp {

DeviceSlot DelayDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    DelayParams instance;
    instance.delayTime = 250.0;
    instance.feedback = 0.4;
    instance.mix = 0.5;
    slot.instance = std::move(instance);
    return slot;
}

DeviceParameterResult DelayDeviceType::setParameter(DeviceSlot& slot,
                                                    std::string_view parameterId,
                                                    float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DelayParams>(slot.instance);
    if (parameterId == "timeMs") {
        instance.delayTime = juce::jlimit(1.0, 2000.0, static_cast<double>(value));
    } else if (parameterId == "feedback") {
        instance.feedback = juce::jlimit(0.0, 0.95, static_cast<double>(value));
    } else if (parameterId == "mix") {
        instance.mix = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool DelayDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> DelayDeviceType::modulatableParams() const {
    return {"gain", "pan", "timeMs", "feedback", "mix"};
}

void DelayDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Delay;
    const auto& inst = std::get<DelayParams>(slot.instance);
    DelayParamsPlayback p;
    p.timeMs = static_cast<float>(inst.delayTime);
    p.feedback = static_cast<float>(inst.feedback);
    p.mix = static_cast<float>(inst.mix);
    // Since Delay snapshot doesn't hold inputGain yet, we can default it to 1.0f
    p.inputGain = 1.0f;
    out.params = p;
}

bool DelayDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const {
    return false;
}

juce::var DelayDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DelayParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("timeMs", inst.delayTime);
    parameters->setProperty("feedback", inst.feedback);
    parameters->setProperty("mix", inst.mix);

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

DeviceSlot DelayDeviceType::varToSlot(const juce::var& obj) const {
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
            DelayParams inst;
            inst.delayTime = p->getProperty("timeMs").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.clamp();
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp