#include "audioapp/devices/GateDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/devices/processors/GateProcessor.hpp"

#include <algorithm>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string GateDeviceType::typeId() const { return device_types::kGate; }

DeviceSlot GateDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = GateParams{};

    slot.config.inputPanel = DynamicsInputPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult GateDeviceType::setParameter(DeviceSlot& slot,
                                                   std::string_view parameterId,
                                                   float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<GateParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) {
        // Legacy: param was historically "inputGain" before full stable name
        if (parameterId == "inputGain")
            id = static_cast<uint16_t>(GateParam::InputGain);
        else
            return result;
    }
    switch (static_cast<GateParam>(id)) {
    case GateParam::InputGain: instance.inputGain = clamped; break;
    case GateParam::Threshold: instance.gateThreshold = clamped; break;
    case GateParam::Attack: instance.gateAttack = clamped; break;
    case GateParam::Release: instance.gateRelease = clamped; break;
    case GateParam::Hold: instance.gateHold = clamped; break;
    case GateParam::Range: instance.gateRange = clamped; break;
    default: return result;
    }
    result.handled = true;
    return result;
}

bool GateDeviceType::setStringParameter(DeviceSlot&,
                                        std::string_view,
                                        const std::string&,
                                        const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> GateDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "gateThreshold", "gateAttack", "gateRelease", "gateHold", "gateRange"};
}

void GateDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                       const PlaybackBuildContext&,
                                       DeviceNodePlayback& out) const {
    auto params = std::get<GateParams>(slot.config.instance);
    const auto& outPanel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    params.gain = outPanel.gain;
    const auto& inPanel = std::get<DynamicsInputPanel>(slot.config.inputPanel);
    params.inputGain = inPanel.trim;
    out.kind = DeviceNodeKind::Gate;
    out.params = params;
}

bool GateDeviceType::buildLiveInstrument(const DeviceSlot&,
                                         const PlaybackBuildContext&,
                                         LiveInstrumentSnapshot&) const {
    return false;
}

juce::var GateDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<GateParams>(slot.config.instance);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("gateThreshold", static_cast<double>(inst.gateThreshold));
    parameters->setProperty("gateAttack", static_cast<double>(inst.gateAttack));
    parameters->setProperty("gateRelease", static_cast<double>(inst.gateRelease));
    parameters->setProperty("gateHold", static_cast<double>(inst.gateHold));
    parameters->setProperty("gateRange", static_cast<double>(inst.gateRange));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));

    // Output panel
    auto* panelObj = new juce::DynamicObject();
    panelObj->setProperty("type", "stereo");
    panelObj->setProperty("gain", static_cast<double>(std::get<StereoOutputPanel>(slot.config.outputPanel).gain));
    panelObj->setProperty("pan", static_cast<double>(std::get<StereoOutputPanel>(slot.config.outputPanel).pan));
    object->setProperty("outputPanel", juce::var(panelObj));

    // Input panel
    auto* inputObj = new juce::DynamicObject();
    inputObj->setProperty("type", "dynamics");
    inputObj->setProperty("trim", static_cast<double>(std::get<DynamicsInputPanel>(slot.config.inputPanel).trim));
    object->setProperty("inputPanel", juce::var(inputObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));

    return juce::var(object);
}

DeviceSlot GateDeviceType::varToSlot(const juce::var& obj) const {
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
            GateParams inst;
            inst.inputGain = readFloat(p, "inputGain", 1.0f);
            inst.gateThreshold = readFloat(p, "gateThreshold", 0.45f);
            inst.gateAttack = readFloat(p, "gateAttack", 0.25f);
            inst.gateRelease = readFloat(p, "gateRelease", 0.50f);
            inst.gateHold = readFloat(p, "gateHold", 0.20f);
            inst.gateRange = readFloat(p, "gateRange", 0.0f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* GateDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<GateProcessor>();
}

DeviceNodeKind GateDeviceType::kind() const noexcept { return DeviceNodeKind::Gate; }

uint16_t GateDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto g = [&](std::string_view n, GateParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = g("gateInputGain", GateParam::InputGain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = g("gateThreshold", GateParam::Threshold); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = g("gateAttack", GateParam::Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = g("gateRelease", GateParam::Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = g("gateHold", GateParam::Hold); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = g("gateRange", GateParam::Range); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view GateDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<GateParam>(localId)) {
    case GateParam::InputGain: return "gateInputGain";
    case GateParam::Threshold: return "gateThreshold";
    case GateParam::Attack: return "gateAttack";
    case GateParam::Release: return "gateRelease";
    case GateParam::Hold: return "gateHold";
    case GateParam::Range: return "gateRange";
    default: return "";
    }
}

std::span<const ParamDescriptor> GateDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(GateParam::InputGain), "gateInputGain", "Input Gain", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(GateParam::Threshold), "gateThreshold", "Threshold", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(GateParam::Attack), "gateAttack", "Attack", 0.25f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(GateParam::Release), "gateRelease", "Release", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(GateParam::Hold), "gateHold", "Hold", 0.20f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(GateParam::Range), "gateRange", "Range", 0.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool GateDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp