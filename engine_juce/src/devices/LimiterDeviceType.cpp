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

    uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) {
        // Legacy: param was historically "inputGain" before full stable name
        if (parameterId == "inputGain")
            id = static_cast<uint16_t>(LimiterParam::InputGain);
        else
            return result;
    }
    switch (static_cast<LimiterParam>(id)) {
    case LimiterParam::InputGain: instance.inputGain = clamped; break;
    case LimiterParam::Ceiling: instance.limitCeiling = clamped; break;
    case LimiterParam::Attack: instance.limitAttack = clamped; break;
    case LimiterParam::Release: instance.limitRelease = clamped; break;
    case LimiterParam::Knee: instance.limitKnee = clamped; break;
    case LimiterParam::Drive: instance.limitDrive = clamped; break;
    case LimiterParam::Makeup: instance.limitMakeup = clamped; break;
    default: return result;
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
    params.gain = 1.0f; // output-panel gain is applied by the device-chain stage
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

DeviceNodeKind LimiterDeviceType::kind() const noexcept { return DeviceNodeKind::Limiter; }

uint16_t LimiterDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto l = [&](std::string_view n, LimiterParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = l("limitInputGain", LimiterParam::InputGain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = l("limitCeiling", LimiterParam::Ceiling); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = l("limitAttack", LimiterParam::Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = l("limitRelease", LimiterParam::Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = l("limitKnee", LimiterParam::Knee); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = l("limitDrive", LimiterParam::Drive); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = l("limitMakeup", LimiterParam::Makeup); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view LimiterDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<LimiterParam>(localId)) {
    case LimiterParam::InputGain: return "limitInputGain";
    case LimiterParam::Ceiling: return "limitCeiling";
    case LimiterParam::Attack: return "limitAttack";
    case LimiterParam::Release: return "limitRelease";
    case LimiterParam::Knee: return "limitKnee";
    case LimiterParam::Drive: return "limitDrive";
    case LimiterParam::Makeup: return "limitMakeup";
    default: return "";
    }
}

std::span<const ParamDescriptor> LimiterDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(LimiterParam::InputGain), "limitInputGain", "Input Gain", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(LimiterParam::Ceiling), "limitCeiling", "Ceiling", 0.85f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(LimiterParam::Attack), "limitAttack", "Attack", 0.10f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(LimiterParam::Release), "limitRelease", "Release", 0.40f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(LimiterParam::Knee), "limitKnee", "Knee", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(LimiterParam::Drive), "limitDrive", "Drive", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(LimiterParam::Makeup), "limitMakeup", "Makeup", 0.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool LimiterDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
