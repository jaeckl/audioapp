#include "audioapp/devices/CrashGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/devices/processors/CrashProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string CrashGeneratorDeviceType::typeId() const {
    return device_types::kCrashGenerator;
}

DeviceSlot CrashGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = CrashGeneratorParams{};

    slot.config.outputPanel = MonoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult CrashGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view parameterId,
                                                             float value) const {
    DeviceParameterResult result;

    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<CrashGeneratorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "crashModel") {
        instance.crashModel = clamped;
    } else if (parameterId == "crashColor") {
        instance.crashColor = clamped;
    } else if (parameterId == "crashSpread") {
        instance.crashSpread = clamped;
    } else if (parameterId == "crashDecay") {
        instance.crashDecay = clamped;
    } else if (parameterId == "crashVelocity") {
        instance.crashVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool CrashGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                  std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CrashGeneratorDeviceType::modulatableParams() const {
    return {"gain", "crashColor", "crashSpread", "crashDecay", "crashVelocity"};
}

void CrashGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext&,
                                                 DeviceNodePlayback& out) const {
    auto params = std::get<CrashGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out.kind = DeviceNodeKind::CrashGenerator;
    out.params = params;
}

bool CrashGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot& out) const {
    auto params = std::get<CrashGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::CrashGenerator;
    out.gain = panel.gain;
    out.crash = params;
    return true;
}

juce::var CrashGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<CrashGeneratorParams>(slot.config.instance);
    parameters->setProperty("crashModel", static_cast<double>(inst.crashModel));
    parameters->setProperty("crashColor", static_cast<double>(inst.crashColor));
    parameters->setProperty("crashSpread", static_cast<double>(inst.crashSpread));
    parameters->setProperty("crashDecay", static_cast<double>(inst.crashDecay));
    parameters->setProperty("crashVelocity", static_cast<double>(inst.crashVelocity));

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

DeviceSlot CrashGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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

            CrashGeneratorParams inst;
            inst.crashModel = readFloat(p, "crashModel", 0.0f);
            if (p->hasProperty("crashColor")) {
                inst.crashColor = readFloat(p, "crashColor", 0.62f);
            } else {
                const float wash = readFloat(p, "crashWash", 0.60f);
                const float bright = readFloat(p, "crashBright", 0.65f);
                inst.crashColor = (wash + bright) * 0.5f;
            }
            inst.crashSpread = readFloat(p, "crashSpread", 0.50f);
            inst.crashDecay = readFloat(p, "crashDecay", 0.55f);
            inst.crashVelocity = readFloat(p, "crashVelocity", 1.0f);
            slot.config.instance = inst;

        }
    }
    return slot;
}

DeviceProcessor* CrashGeneratorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<CrashProcessor>();
}

DeviceNodeKind CrashGeneratorDeviceType::kind() const noexcept { return DeviceNodeKind::CrashGenerator; }

uint16_t CrashGeneratorDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto c = [&](std::string_view n, CrashParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : 0;
    };
    if (auto v = c("crashColor", CrashParam::Color)) return v;
    if (auto v = c("crashSpread", CrashParam::Spread)) return v;
    if (auto v = c("crashDecay", CrashParam::Decay)) return v;
    if (auto v = c("crashVelocity", CrashParam::Velocity)) return v;
    return 0;
}

std::string_view CrashGeneratorDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<CrashParam>(localId)) {
    case CrashParam::Color: return "crashColor";
    case CrashParam::Spread: return "crashSpread";
    case CrashParam::Decay: return "crashDecay";
    case CrashParam::Velocity: return "crashVelocity";
    default: return "";
    }
}

std::span<const ParamDescriptor> CrashGeneratorDeviceType::paramDescriptors() const noexcept {
    return {};
}

bool CrashGeneratorDeviceType::usesDspAutomationSubBlocks() const noexcept {
    return false;
}

} // namespace audioapp
