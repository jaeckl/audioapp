#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DelayDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/DelayParams.hpp"
#include "juce_dsp/juce_dsp.h"
#include "audioapp/devices/processors/DelayProcessor.hpp"

namespace audioapp {

DeviceSlot DelayDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DelayParams instance;
    instance.delayTime = 250.0;
    instance.feedback = 0.4;
    instance.mix = 0.5;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
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
    auto& instance = std::get<DelayParams>(slot.config.instance);
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
    const auto& inst = std::get<DelayParams>(slot.config.instance);
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
    const auto& inst = std::get<DelayParams>(slot.config.instance);
    parameters->setProperty("timeMs", inst.delayTime);
    parameters->setProperty("feedback", inst.feedback);
    parameters->setProperty("mix", inst.mix);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
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
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            StereoOutputPanel sp;
            sp.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            sp.pan = static_cast<float>(static_cast<double>(panel->getProperty("pan")));
            slot.config.outputPanel = sp;

        }

        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;

        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };

            if (!hasPanel) {
                const float oldGain = readFloat("gain", 1.0f);
                const float oldPan = readFloat("pan", 0.5f);
                slot.config.outputPanel = StereoOutputPanel{oldGain, oldPan};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            DelayParams inst;
            inst.delayTime = p->getProperty("timeMs").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
            
        }
    }
    return slot;
}

DeviceProcessor* DelayDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DelayProcessor>();
}

} // namespace audioapp
