#include "audioapp/devices/SnareGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/devices/processors/SnareProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string SnareGeneratorDeviceType::typeId() const {
    return device_types::kSnareGenerator;
}

DeviceSlot SnareGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = SnareGeneratorParams{};

    slot.config.outputPanel = MonoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult SnareGeneratorDeviceType::setParameter(DeviceSlot& slot,
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

    auto& instance = std::get<SnareGeneratorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    switch (static_cast<SnareParam>(localId)) {
    case SnareParam::Model:    instance.snareModel = clamped; break;
    case SnareParam::Body:     instance.snareBody = clamped; break;
    case SnareParam::Ring:     instance.snareRing = clamped; break;
    case SnareParam::Tune:     instance.snareTune = clamped; break;
    case SnareParam::Snares:   instance.snareSnares = clamped; break;
    case SnareParam::Snap:     instance.snareSnap = clamped; break;
    case SnareParam::Decay:    instance.snareDecay = clamped; break;
    case SnareParam::Velocity: instance.snareVelocity = clamped; break;
    default: return result;
    }

    result.handled = true;
    return result;
}

bool SnareGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                  std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SnareGeneratorDeviceType::modulatableParams() const {
    return {"gain", "snareModel", "snareBody", "snareRing", "snareTune", "snareSnares",
            "snareSnap", "snareDecay", "snareVelocity"};
}

void SnareGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext&,
                                                 DeviceNodePlayback& out) const {
    auto params = std::get<SnareGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out.kind = DeviceNodeKind::SnareGenerator;
    out.params = params;
}

bool SnareGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot& out) const {
    auto params = std::get<SnareGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::SnareGenerator;
    out.gain = panel.gain;
    out.snare = params;
    return true;
}

juce::var SnareGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<SnareGeneratorParams>(slot.config.instance);
    parameters->setProperty("snareModel", static_cast<double>(inst.snareModel));
    parameters->setProperty("snareBody", static_cast<double>(inst.snareBody));
    parameters->setProperty("snareRing", static_cast<double>(inst.snareRing));
    parameters->setProperty("snareTune", static_cast<double>(inst.snareTune));
    parameters->setProperty("snareSnares", static_cast<double>(inst.snareSnares));
    parameters->setProperty("snareSnap", static_cast<double>(inst.snareSnap));
    parameters->setProperty("snareDecay", static_cast<double>(inst.snareDecay));
    parameters->setProperty("snareVelocity", static_cast<double>(inst.snareVelocity));

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

DeviceSlot SnareGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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
            float oldGain = 1.0f;
            bool hasOutputPanel = outputPanelVar.getDynamicObject() != nullptr;

            if (!hasOutputPanel) {
                oldGain = readFloat(p, "gain", 1.0f);

                const float oldPan = readFloat(p, "pan", 0.5f);

                const float oldBypass = readFloat(p, "bypass", 0.0f);

                slot.config.bypassed = oldBypass >= 0.5f;
                slot.config.outputPanel = MonoOutputPanel{oldGain};
            }

            SnareGeneratorParams inst;
            inst.snareModel = readFloat(p, "snareModel", 0.0f);
            inst.snareBody = readFloat(p, "snareBody", 0.45f);
            inst.snareRing = readFloat(p, "snareRing", 0.40f);
            inst.snareTune = readFloat(p, "snareTune", 0.50f);
            inst.snareSnares = readFloat(p, "snareSnares", 0.60f);
            inst.snareSnap = readFloat(p, "snareSnap", 0.40f);
            inst.snareDecay = readFloat(p, "snareDecay", 0.50f);
            inst.snareVelocity = readFloat(p, "snareVelocity", 1.0f);
            slot.config.instance = inst;

        }
    }
    return slot;
}

DeviceProcessor* SnareGeneratorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<SnareProcessor>();
}

DeviceNodeKind SnareGeneratorDeviceType::kind() const noexcept { return DeviceNodeKind::SnareGenerator; }

uint16_t SnareGeneratorDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto s = [&](std::string_view n, SnareParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = s("snareModel", SnareParam::Model); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareBody", SnareParam::Body); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareRing", SnareParam::Ring); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareTune", SnareParam::Tune); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareSnares", SnareParam::Snares); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareSnap", SnareParam::Snap); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareDecay", SnareParam::Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("snareVelocity", SnareParam::Velocity); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view SnareGeneratorDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<SnareParam>(localId)) {
    case SnareParam::Model: return "snareModel";
    case SnareParam::Body: return "snareBody";
    case SnareParam::Ring: return "snareRing";
    case SnareParam::Tune: return "snareTune";
    case SnareParam::Snares: return "snareSnares";
    case SnareParam::Snap: return "snareSnap";
    case SnareParam::Decay: return "snareDecay";
    case SnareParam::Velocity: return "snareVelocity";
    default: return "";
    }
}

std::span<const ParamDescriptor> SnareGeneratorDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(SnareParam::Model), "snareModel", "Model", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Body), "snareBody", "Body", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Ring), "snareRing", "Ring", 0.40f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Tune), "snareTune", "Tune", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Snares), "snareSnares", "Snares", 0.60f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Snap), "snareSnap", "Snap", 0.40f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Decay), "snareDecay", "Decay", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(SnareParam::Velocity), "snareVelocity", "Velocity", 1.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool SnareGeneratorDeviceType::usesDspAutomationSubBlocks() const noexcept {
    return false;
}

} // namespace audioapp
