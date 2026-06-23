#include "audioapp/devices/ExpanderDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/devices/processors/ExpanderProcessor.hpp"

#include <juce_core/juce_core.h>

#include <algorithm>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string ExpanderDeviceType::typeId() const { return device_types::kExpander; }

DeviceSlot ExpanderDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = ExpanderParams{};

    slot.config.inputPanel = DynamicsInputPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult ExpanderDeviceType::setParameter(DeviceSlot& slot,
                                                       std::string_view parameterId,
                                                       float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ExpanderParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "expandThreshold") {
        instance.expandThreshold = clamped;
    } else if (parameterId == "expandRatio") {
        instance.expandRatio = clamped;
    } else if (parameterId == "expandAttack") {
        instance.expandAttack = clamped;
    } else if (parameterId == "expandRelease") {
        instance.expandRelease = clamped;
    } else if (parameterId == "expandRange") {
        instance.expandRange = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool ExpanderDeviceType::setStringParameter(DeviceSlot&,
                                            std::string_view,
                                            const std::string&,
                                            const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ExpanderDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "expandThreshold", "expandRatio", "expandAttack", "expandRelease",
            "expandRange"};
}

void ExpanderDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                           const PlaybackBuildContext&,
                                           DeviceNodePlayback& out) const {
    auto params = std::get<ExpanderParams>(slot.config.instance);
    const auto& outPanel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    params.gain = outPanel.gain;
    const auto& inPanel = std::get<DynamicsInputPanel>(slot.config.inputPanel);
    params.inputGain = inPanel.trim;
    out.kind = DeviceNodeKind::Expander;
    out.params = params;
}

bool ExpanderDeviceType::buildLiveInstrument(const DeviceSlot&,
                                             const PlaybackBuildContext&,
                                             LiveInstrumentSnapshot&) const {
    return false;
}

juce::var ExpanderDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ExpanderParams>(slot.config.instance);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("expandThreshold", static_cast<double>(inst.expandThreshold));
    parameters->setProperty("expandRatio", static_cast<double>(inst.expandRatio));
    parameters->setProperty("expandAttack", static_cast<double>(inst.expandAttack));
    parameters->setProperty("expandRelease", static_cast<double>(inst.expandRelease));
    parameters->setProperty("expandRange", static_cast<double>(inst.expandRange));

    // Output panel
    auto* panelObj = new juce::DynamicObject();
    panelObj->setProperty("type", "stereo");
    panelObj->setProperty("gain", static_cast<double>(std::get<StereoOutputPanel>(slot.config.outputPanel).gain));
    panelObj->setProperty("pan", static_cast<double>(std::get<StereoOutputPanel>(slot.config.outputPanel).pan));

    // Input panel
    auto* inputObj = new juce::DynamicObject();
    inputObj->setProperty("type", "dynamics");
    inputObj->setProperty("trim", static_cast<double>(std::get<DynamicsInputPanel>(slot.config.inputPanel).trim));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("outputPanel", juce::var(panelObj));
    object->setProperty("inputPanel", juce::var(inputObj));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot ExpanderDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto paramsVar = object->getProperty("parameters");
        const auto* p = paramsVar.getDynamicObject();

        // Output panel: new format or legacy fallback from parameters
        const auto outputPanelVar = object->getProperty("outputPanel");
        if (const auto* op = outputPanelVar.getDynamicObject()) {
            auto readFloat = [](const juce::DynamicObject* src, const char* key, float fallback) -> float {
                if (!src) return fallback;
                const auto v = src->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            StereoOutputPanel panel;
            panel.gain = readFloat(op, "gain", 1.0f);
            panel.pan = readFloat(op, "pan", 0.5f);
            slot.config.outputPanel = panel;

        } else if (p) {
            auto readFloat = [](const juce::DynamicObject* src, const char* key, float fallback) -> float {
                if (!src) return fallback;
                const auto v = src->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            StereoOutputPanel panel;
            panel.gain = readFloat(p, "gain", 1.0f);
            panel.pan = readFloat(p, "pan", 0.5f);
            slot.config.outputPanel = panel;

        }

        // Input panel: new format or legacy fallback
        const auto inputPanelVar = object->getProperty("inputPanel");
        if (const auto* ip = inputPanelVar.getDynamicObject()) {
            auto readFloat = [](const juce::DynamicObject* src, const char* key, float fallback) -> float {
                if (!src) return fallback;
                const auto v = src->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            const std::string type = ip->getProperty("type").toString().toStdString();
            if (type == "dynamics") {
                slot.config.inputPanel = DynamicsInputPanel{readFloat(ip, "trim", 1.0f)};
            }
        } else if (p) {
            auto readFloat = [](const juce::DynamicObject* src, const char* key, float fallback) -> float {
                if (!src) return fallback;
                const auto v = src->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            const float ig = readFloat(p, "inputGain", -1.0f);
            if (ig >= 0.0f) {
                slot.config.inputPanel = DynamicsInputPanel{ig};
            }
        }

        // Bypass from root
        {
            auto readFloat = [](const juce::DynamicObject* src, const char* key, float fallback) -> float {
                if (!src) return fallback;
                const auto v = src->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            slot.config.bypassed = readFloat(object, "bypass", 0.0f) >= 0.5f;

        }

        // Device-specific parameters
        if (p) {
            auto readFloat = [](const juce::DynamicObject* src, const char* key, float fallback) -> float {
                if (!src) return fallback;
                const auto v = src->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            ExpanderParams inst;
            inst.inputGain = readFloat(p, "inputGain", 1.0f);
            inst.expandThreshold = readFloat(p, "expandThreshold", 0.40f);
            inst.expandRatio = readFloat(p, "expandRatio", 0.45f);
            inst.expandAttack = readFloat(p, "expandAttack", 0.25f);
            inst.expandRelease = readFloat(p, "expandRelease", 0.55f);
            inst.expandRange = readFloat(p, "expandRange", 0.15f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* ExpanderDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ExpanderProcessor>();
}

} // namespace audioapp
