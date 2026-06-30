#include "audioapp/devices/CymbalGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/CymbalAlgorithm.hpp"
#include "audioapp/devices/processors/CymbalProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string CymbalGeneratorDeviceType::typeId() const {
    return device_types::kCymbalGenerator;
}

DeviceSlot CymbalGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = CymbalGeneratorParams{};

    slot.config.outputPanel = MonoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult CymbalGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                              std::string_view parameterId,
                                                              float value) const {
    DeviceParameterResult result;

    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    const uint16_t localId = paramIdFromString(parameterId);
    if (localId == static_cast<uint16_t>(-1))
        return result;

    auto& instance = std::get<CymbalGeneratorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    switch (static_cast<CymbalParam>(localId)) {
    case CymbalParam::Model:    instance.cymbalModel = clamped; break;
    case CymbalParam::Color:    instance.cymbalColor = clamped; break;
    case CymbalParam::Decay:    instance.cymbalDecay = clamped; break;
    case CymbalParam::Width:    instance.cymbalWidth = clamped; break;
    case CymbalParam::Velocity: instance.cymbalVelocity = clamped; break;
    default: return result;
    }

    result.handled = true;
    return result;
}

bool CymbalGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                   std::string_view,
                                                   const std::string&,
                                                   const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CymbalGeneratorDeviceType::modulatableParams() const {
    return {"gain", "cymbalColor", "cymbalDecay", "cymbalWidth", "cymbalVelocity"};
}

void CymbalGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  DeviceNodePlayback& out) const {
    auto params = std::get<CymbalGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = 1.0f; // output-panel gain is applied by the device-chain stage
    out.kind = DeviceNodeKind::CymbalGenerator;
    out.params = params;
}

bool CymbalGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                    const PlaybackBuildContext&,
                                                    LiveInstrumentSnapshot& out) const {
    auto params = std::get<CymbalGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::CymbalGenerator;
    out.gain = panel.gain;
    out.cymbal = params;
    return true;
}

juce::var CymbalGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<CymbalGeneratorParams>(slot.config.instance);
    parameters->setProperty("cymbalModel", static_cast<double>(inst.cymbalModel));
    parameters->setProperty("cymbalColor", static_cast<double>(inst.cymbalColor));
    parameters->setProperty("cymbalDecay", static_cast<double>(inst.cymbalDecay));
    parameters->setProperty("cymbalWidth", static_cast<double>(inst.cymbalWidth));
    parameters->setProperty("cymbalVelocity", static_cast<double>(inst.cymbalVelocity));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));

    auto* panelObj = new juce::DynamicObject();
    panelObj->setProperty("type", "mono");
    panelObj->setProperty("gain", static_cast<double>(std::get<MonoOutputPanel>(slot.config.outputPanel).gain));
    object->setProperty("outputPanel", juce::var(panelObj));

    auto* inputObj = new juce::DynamicObject();
    inputObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inputObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);

    return juce::var(object);
}

DeviceSlot CymbalGeneratorDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        auto readFloat = [&](const juce::DynamicObject* p, const char* key, float fallback) -> float {
            const auto v = p->getProperty(key);
            if (v.isDouble() || v.isInt() || v.isInt64())
                return static_cast<float>(static_cast<double>(v));
            return fallback;
        };

        const auto outputPanelVar = object->getProperty("outputPanel");
        if (const auto* panelObj = outputPanelVar.getDynamicObject()) {
            const float panelGain = readFloat(panelObj, "gain", 1.0f);
            slot.config.outputPanel = MonoOutputPanel{panelGain};

        }

        const auto bypassVar = object->getProperty("bypass");
        if (bypassVar.isDouble() || bypassVar.isInt() || bypassVar.isInt64()) {
            slot.config.bypassed = static_cast<float>(static_cast<double>(bypassVar)) >= 0.5f;

        }

        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            bool hasOutputPanel = outputPanelVar.getDynamicObject() != nullptr;

            if (!hasOutputPanel) {
                const float oldGain = readFloat(p, "gain", 1.0f);

                const float oldPan = readFloat(p, "pan", 0.5f);

                const float oldBypass = readFloat(p, "bypass", 0.0f);

                slot.config.bypassed = oldBypass >= 0.5f;
                slot.config.outputPanel = MonoOutputPanel{oldGain};
            }

            CymbalGeneratorParams inst;
            inst.cymbalModel = readFloat(p, "cymbalModel", 0.0f);
            if (p->hasProperty("cymbalColor")) {
                inst.cymbalColor = readFloat(p, "cymbalColor", 0.68f);
            } else {
                const float metal = readFloat(p, "cymbalMetal", 0.55f);
                const float brightness = readFloat(p, "cymbalBrightness", 0.60f);
                inst.cymbalColor = (metal + brightness) * 0.5f;
            }
            inst.cymbalDecay = readFloat(p, "cymbalDecay", 0.50f);
            inst.cymbalWidth = readFloat(p, "cymbalWidth", 0.35f);
            inst.cymbalVelocity = readFloat(p, "cymbalVelocity", 1.0f);
            slot.config.instance = inst;

        }
    }
    return slot;
}

DeviceProcessor* CymbalGeneratorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<CymbalProcessor>();
}

DeviceNodeKind CymbalGeneratorDeviceType::kind() const noexcept { return DeviceNodeKind::CymbalGenerator; }

uint16_t CymbalGeneratorDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto c = [&](std::string_view n, CymbalParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = c("cymbalModel", CymbalParam::Model); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("cymbalColor", CymbalParam::Color); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("cymbalDecay", CymbalParam::Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("cymbalWidth", CymbalParam::Width); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = c("cymbalVelocity", CymbalParam::Velocity); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view CymbalGeneratorDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<CymbalParam>(localId)) {
    case CymbalParam::Model: return "cymbalModel";
    case CymbalParam::Color: return "cymbalColor";
    case CymbalParam::Decay: return "cymbalDecay";
    case CymbalParam::Width: return "cymbalWidth";
    case CymbalParam::Velocity: return "cymbalVelocity";
    default: return "";
    }
}

std::span<const ParamDescriptor> CymbalGeneratorDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(CymbalParam::Model), "cymbalModel", "Model", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CymbalParam::Color), "cymbalColor", "Color", 0.68f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CymbalParam::Decay), "cymbalDecay", "Decay", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CymbalParam::Width), "cymbalWidth", "Width", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(CymbalParam::Velocity), "cymbalVelocity", "Velocity", 1.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool CymbalGeneratorDeviceType::usesDspAutomationSubBlocks() const noexcept {
    return false;
}

} // namespace audioapp
