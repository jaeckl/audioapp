// PhaserDeviceType implementation
#include "audioapp/effects/PhaserDeviceType.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/PhaserParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "juce_dsp/juce_dsp.h"

namespace audioapp {

DeviceSlot PhaserDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    PhaserParams instance;
    instance.depth = 0.5;
    instance.rateHz = 0.8;
    instance.feedback = 0.3;
    instance.centreFrequencyHz = 1000.0;
    slot.instance = std::move(instance);
    return slot;
}

DeviceParameterResult PhaserDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<PhaserParams>(slot.instance);
    if (parameterId == "depth") {
        instance.depth = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "rateHz") {
        instance.rateHz = juce::jlimit(0.1, 5.0, static_cast<double>(value));
    } else if (parameterId == "feedback") {
        instance.feedback = juce::jlimit(0.0, 0.95, static_cast<double>(value));
    } else if (parameterId == "centreFrequencyHz") {
        instance.centreFrequencyHz = juce::jlimit(20.0, 20000.0, static_cast<double>(value));
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool PhaserDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> PhaserDeviceType::modulatableParams() const {
    return {"gain", "pan", "depth", "rateHz", "feedback", "centreFrequencyHz"};
}

void PhaserDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Phaser;
    const auto& inst = std::get<PhaserParams>(slot.instance);
    PhaserParamsPlayback p;
    p.depth = static_cast<float>(inst.depth);
    p.rateHz = static_cast<float>(inst.rateHz);
    p.feedback = static_cast<float>(inst.feedback);
    p.centreFrequencyHz = static_cast<float>(inst.centreFrequencyHz);
    p.inputGain = 1.0f;
    out.params = p;
}

bool PhaserDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var PhaserDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<PhaserParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("depth", inst.depth);
    parameters->setProperty("rateHz", inst.rateHz);
    parameters->setProperty("feedback", inst.feedback);
    parameters->setProperty("centreFrequencyHz", inst.centreFrequencyHz);

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

DeviceSlot PhaserDeviceType::varToSlot(const juce::var& obj) const {
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
            PhaserParams inst;
            inst.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.rateHz = p->getProperty("rateHz").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.centreFrequencyHz = p->getProperty("centreFrequencyHz").toString().getDoubleValue();
            inst.clamp();
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp