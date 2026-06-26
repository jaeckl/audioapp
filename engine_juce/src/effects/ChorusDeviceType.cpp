#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/ChorusDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/ChorusParams.hpp"
#include "juce_dsp/juce_dsp.h"
#include "audioapp/devices/processors/ChorusProcessor.hpp"

namespace audioapp {

DeviceSlot ChorusDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    ChorusParams instance;
    instance.depth = 0.25;
    instance.rateHz = 1.5;
    instance.mix = 0.4;
    instance.centreDelayMs = 7.0;
    instance.feedback = 0.0;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
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
    auto& instance = std::get<ChorusParams>(slot.config.instance);
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
    const auto& inst = std::get<ChorusParams>(slot.config.instance);
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
    const auto& inst = std::get<ChorusParams>(slot.config.instance);
    parameters->setProperty("depth", inst.depth);
    parameters->setProperty("rateHz", inst.rateHz);
    parameters->setProperty("mix", inst.mix);
    parameters->setProperty("centreDelayMs", inst.centreDelayMs);
    parameters->setProperty("feedback", inst.feedback);

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

DeviceSlot ChorusDeviceType::varToSlot(const juce::var& obj) const {
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

            ChorusParams inst;
            inst.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.rateHz = p->getProperty("rateHz").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.centreDelayMs = p->getProperty("centreDelayMs").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
            
        }
    }
    return slot;
}

DeviceProcessor* ChorusDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ChorusProcessor>();
}

DeviceNodeKind ChorusDeviceType::kind() const noexcept { return DeviceNodeKind::Chorus; }

uint16_t ChorusDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto c = [&](std::string_view n, uint16_t pid) -> uint16_t {
        return name == n ? pid : 0;
    };
    if (auto v = c("chorusDepth", 0)) return v;
    if (auto v = c("chorusRateHz", 1)) return v;
    if (auto v = c("chorusMix", 2)) return v;
    if (auto v = c("chorusCentreDelayMs", 3)) return v;
    if (auto v = c("chorusFeedback", 4)) return v;
    return 0;
}

std::string_view ChorusDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (localId) {
    case 0: return "chorusDepth";
    case 1: return "chorusRateHz";
    case 2: return "chorusMix";
    case 3: return "chorusCentreDelayMs";
    case 4: return "chorusFeedback";
    default: return "";
    }
}

std::span<const ParamDescriptor> ChorusDeviceType::paramDescriptors() const noexcept { return {}; }

bool ChorusDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
