#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/ReverbDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/ReverbParams.hpp"
#include <juce_core/juce_core.h>
#include "audioapp/devices/processors/ReverbProcessor.hpp"

namespace audioapp {

DeviceSlot ReverbDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    ReverbParams instance;
    instance.roomSize = 0.5;
    instance.damping = 0.5;
    instance.wetLevel = 0.33;
    instance.dryLevel = 0.7;
    instance.width = 1.0;
    instance.freezeMode = false;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult ReverbDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ReverbParams>(slot.config.instance);
    if (parameterId == "roomSize") {
        instance.roomSize = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "damping") {
        instance.damping = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "wetLevel") {
        instance.wetLevel = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "dryLevel") {
        instance.dryLevel = juce::jlimit(0.0, 1.0, static_cast<double>(value));
    } else if (parameterId == "width") {
        instance.width = juce::jlimit(0.0, 1.0, static_cast<double>(value));
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

void ReverbDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Reverb;
    const auto& inst = std::get<ReverbParams>(slot.config.instance);
    ReverbParamsPlayback p;
    p.roomSize = static_cast<float>(inst.roomSize);
    p.damping = static_cast<float>(inst.damping);
    p.wetLevel = static_cast<float>(inst.wetLevel);
    p.dryLevel = static_cast<float>(inst.dryLevel);
    p.width = static_cast<float>(inst.width);
    p.inputGain = 1.0f;
    out.params = p;
}

bool ReverbDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var ReverbDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ReverbParams>(slot.config.instance);
    parameters->setProperty("roomSize", inst.roomSize);
    parameters->setProperty("damping", inst.damping);
    parameters->setProperty("wetLevel", inst.wetLevel);
    parameters->setProperty("dryLevel", inst.dryLevel);
    parameters->setProperty("width", inst.width);
    parameters->setProperty("freezeMode", inst.freezeMode ? 1.0 : 0.0);

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

DeviceSlot ReverbDeviceType::varToSlot(const juce::var& obj) const {
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

            ReverbParams inst;
            inst.roomSize = p->getProperty("roomSize").toString().getDoubleValue();
            inst.damping = p->getProperty("damping").toString().getDoubleValue();
            inst.wetLevel = p->getProperty("wetLevel").toString().getDoubleValue();
            inst.dryLevel = p->getProperty("dryLevel").toString().getDoubleValue();
            inst.width = p->getProperty("width").toString().getDoubleValue();
            inst.freezeMode = static_cast<bool>(p->getProperty("freezeMode"));
            inst.clamp();
            slot.config.instance = inst;
            
        }
    }
    return slot;
}

DeviceProcessor* ReverbDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ReverbProcessor>();
}

} // namespace audioapp
