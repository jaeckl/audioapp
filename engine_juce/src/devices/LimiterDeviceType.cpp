#include "audioapp/devices/LimiterDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/devices/processors/LimiterProcessor.hpp"

#include <algorithm>
#include <juce_core/juce_core.h>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string LimiterDeviceType::typeId() const { return device_types::kLimiter; }

DeviceSlot LimiterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = LimiterParams{};

    slot.config.inputPanel = DynamicsInputPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult LimiterDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<LimiterParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "limitCeiling") {
        instance.limitCeiling = clamped;
    } else if (parameterId == "limitAttack") {
        instance.limitAttack = clamped;
    } else if (parameterId == "limitRelease") {
        instance.limitRelease = clamped;
    } else if (parameterId == "limitKnee") {
        instance.limitKnee = clamped;
    } else if (parameterId == "limitDrive") {
        instance.limitDrive = clamped;
    } else if (parameterId == "limitMakeup") {
        instance.limitMakeup = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool LimiterDeviceType::setStringParameter(DeviceSlot&,
                                           std::string_view,
                                           const std::string&,
                                           const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> LimiterDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "limitCeiling", "limitAttack", "limitRelease", "limitKnee",
            "limitDrive", "limitMakeup"};
}

void LimiterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                          const PlaybackBuildContext&,
                                          DeviceNodePlayback& out) const {
    auto params = std::get<LimiterParams>(slot.config.instance);
    const auto& outPanel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    params.gain = outPanel.gain;
    const auto& inPanel = std::get<DynamicsInputPanel>(slot.config.inputPanel);
    params.inputGain = inPanel.trim;
    out.kind = DeviceNodeKind::Limiter;
    out.params = params;
}

bool LimiterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                            const PlaybackBuildContext&,
                                            LiveInstrumentSnapshot&) const {
    return false;
}

juce::var LimiterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<LimiterParams>(slot.config.instance);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("limitCeiling", static_cast<double>(inst.limitCeiling));
    parameters->setProperty("limitAttack", static_cast<double>(inst.limitAttack));
    parameters->setProperty("limitRelease", static_cast<double>(inst.limitRelease));
    parameters->setProperty("limitKnee", static_cast<double>(inst.limitKnee));
    parameters->setProperty("limitDrive", static_cast<double>(inst.limitDrive));
    parameters->setProperty("limitMakeup", static_cast<double>(inst.limitMakeup));

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
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("outputPanel", juce::var(panelObj));
    object->setProperty("inputPanel", juce::var(inputObj));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot LimiterDeviceType::varToSlot(const juce::var& obj) const {
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
            LimiterParams inst;
            inst.inputGain = readFloat(p, "inputGain", 1.0f);
            inst.limitCeiling = readFloat(p, "limitCeiling", 0.85f);
            inst.limitAttack = readFloat(p, "limitAttack", 0.10f);
            inst.limitRelease = readFloat(p, "limitRelease", 0.40f);
            inst.limitKnee = readFloat(p, "limitKnee", 0.0f);
            inst.limitDrive = readFloat(p, "limitDrive", 0.0f);
            inst.limitMakeup = readFloat(p, "limitMakeup", 0.0f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* LimiterDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<LimiterProcessor>();
}

} // namespace audioapp
