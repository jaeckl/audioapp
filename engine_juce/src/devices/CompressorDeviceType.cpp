#include "audioapp/devices/CompressorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/devices/processors/CompressorProcessor.hpp"

#include <algorithm>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string CompressorDeviceType::typeId() const { return device_types::kCompressor; }

DeviceSlot CompressorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = CompressorParams{};

    slot.config.inputPanel = DynamicsInputPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult CompressorDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<CompressorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) {
        // Legacy: param was historically "inputGain" before full stable name
        if (parameterId == "inputGain")
            id = static_cast<uint16_t>(CompressorParam::InputGain);
        else
            return result;
    }
    switch (static_cast<CompressorParam>(id)) {
    case CompressorParam::InputGain: instance.inputGain = clamped; break;
    case CompressorParam::Threshold: instance.compThreshold = clamped; break;
    case CompressorParam::Ratio: instance.compRatio = clamped; break;
    case CompressorParam::Attack: instance.compAttack = clamped; break;
    case CompressorParam::Release: instance.compRelease = clamped; break;
    case CompressorParam::Knee: instance.compKnee = clamped; break;
    case CompressorParam::Makeup: instance.compMakeup = clamped; break;
    default: return result;
    }
    result.handled = true;
    return result;
}

bool CompressorDeviceType::setStringParameter(DeviceSlot&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CompressorDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "compThreshold", "compRatio", "compAttack", "compRelease", "compKnee",
            "compMakeup"};
}

void CompressorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    auto params = std::get<CompressorParams>(slot.config.instance);
    const auto& outPanel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    params.gain = outPanel.gain;
    const auto& inPanel = std::get<DynamicsInputPanel>(slot.config.inputPanel);
    params.inputGain = inPanel.trim;
    out.kind = DeviceNodeKind::Compressor;
    out.params = params;
}

bool CompressorDeviceType::buildLiveInstrument(const DeviceSlot&,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot&) const {
    return false;
}

juce::var CompressorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<CompressorParams>(slot.config.instance);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("compThreshold", static_cast<double>(inst.compThreshold));
    parameters->setProperty("compRatio", static_cast<double>(inst.compRatio));
    parameters->setProperty("compAttack", static_cast<double>(inst.compAttack));
    parameters->setProperty("compRelease", static_cast<double>(inst.compRelease));
    parameters->setProperty("compKnee", static_cast<double>(inst.compKnee));
    parameters->setProperty("compMakeup", static_cast<double>(inst.compMakeup));

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

DeviceSlot CompressorDeviceType::varToSlot(const juce::var& obj) const {
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
            CompressorParams inst;
            inst.inputGain = readFloat(p, "inputGain", 1.0f);
            inst.compThreshold = readFloat(p, "compThreshold", 0.55f);
            inst.compRatio = readFloat(p, "compRatio", 0.50f);
            inst.compAttack = readFloat(p, "compAttack", 0.20f);
            inst.compRelease = readFloat(p, "compRelease", 0.55f);
            inst.compKnee = readFloat(p, "compKnee", 0.25f);
            inst.compMakeup = readFloat(p, "compMakeup", 0.35f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* CompressorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<CompressorProcessor>();
}

DeviceNodeKind CompressorDeviceType::kind() const noexcept { return DeviceNodeKind::Compressor; }

uint16_t CompressorDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto c = [&](std::string_view n, CompressorParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = c("compInputGain", CompressorParam::InputGain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("compThreshold", CompressorParam::Threshold); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("compRatio", CompressorParam::Ratio); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("compAttack", CompressorParam::Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("compRelease", CompressorParam::Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("compKnee", CompressorParam::Knee); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("compMakeup", CompressorParam::Makeup); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view CompressorDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<CompressorParam>(localId)) {
    case CompressorParam::InputGain: return "compInputGain";
    case CompressorParam::Threshold: return "compThreshold";
    case CompressorParam::Ratio: return "compRatio";
    case CompressorParam::Attack: return "compAttack";
    case CompressorParam::Release: return "compRelease";
    case CompressorParam::Knee: return "compKnee";
    case CompressorParam::Makeup: return "compMakeup";
    default: return "";
    }
}

std::span<const ParamDescriptor> CompressorDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(CompressorParam::InputGain), "compInputGain", "Input Gain", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CompressorParam::Threshold), "compThreshold", "Threshold", 0.55f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CompressorParam::Ratio), "compRatio", "Ratio", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CompressorParam::Attack), "compAttack", "Attack", 0.20f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CompressorParam::Release), "compRelease", "Release", 0.55f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CompressorParam::Knee), "compKnee", "Knee", 0.25f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CompressorParam::Makeup), "compMakeup", "Makeup", 0.35f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool CompressorDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp