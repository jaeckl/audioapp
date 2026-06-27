#include "audioapp/devices/KickGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/devices/processors/KickProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string KickGeneratorDeviceType::typeId() const {
    return device_types::kKickGenerator;
}

DeviceSlot KickGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = KickGeneratorParams{};

    slot.config.outputPanel = MonoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult KickGeneratorDeviceType::setParameter(DeviceSlot& slot,
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

    auto& instance = std::get<KickGeneratorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    switch (static_cast<KickParam>(localId)) {
    case KickParam::Model:    instance.kickModel = clamped; break;
    case KickParam::Pitch:    instance.kickPitch = clamped; break;
    case KickParam::Punch:    instance.kickPunch = clamped; break;
    case KickParam::Decay:    instance.kickDecay = clamped; break;
    case KickParam::Click:    instance.kickClick = clamped; break;
    case KickParam::Tone:     instance.kickTone = clamped; break;
    case KickParam::Velocity: instance.kickVelocity = clamped; break;
    case KickParam::KeyTrack: instance.kickKeyTrack = clamped >= 0.5f ? 1.0f : 0.0f; break;
    default: return result;
    }

    result.handled = true;
    return result;
}

bool KickGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                 std::string_view,
                                                 const std::string&,
                                                 const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> KickGeneratorDeviceType::modulatableParams() const {
    return {"gain", "kickPitch", "kickPunch", "kickDecay", "kickClick", "kickTone",
            "kickVelocity", "kickKeyTrack"};
}

void KickGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    auto params = std::get<KickGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out.kind = DeviceNodeKind::KickGenerator;
    out.params = params;
}

bool KickGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    auto params = std::get<KickGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::KickGenerator;
    out.gain = panel.gain;
    out.kick = params;
    return true;
}

juce::var KickGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<KickGeneratorParams>(slot.config.instance);
    parameters->setProperty("kickModel", static_cast<double>(inst.kickModel));
    parameters->setProperty("kickPitch", static_cast<double>(inst.kickPitch));
    parameters->setProperty("kickPunch", static_cast<double>(inst.kickPunch));
    parameters->setProperty("kickDecay", static_cast<double>(inst.kickDecay));
    parameters->setProperty("kickClick", static_cast<double>(inst.kickClick));
    parameters->setProperty("kickTone", static_cast<double>(inst.kickTone));
    parameters->setProperty("kickVelocity", static_cast<double>(inst.kickVelocity));
    parameters->setProperty("kickKeyTrack", static_cast<double>(inst.kickKeyTrack));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    // Write outputPanel
    auto* panelObj = new juce::DynamicObject();
    panelObj->setProperty("type", "mono");
    panelObj->setProperty("gain", static_cast<double>(std::get<MonoOutputPanel>(slot.config.outputPanel).gain));
    object->setProperty("outputPanel", juce::var(panelObj));

    // Write inputPanel
    auto* inputObj = new juce::DynamicObject();
    inputObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inputObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot KickGeneratorDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        // Read outputPanel (new format) or fall back to legacy parameters
        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            auto pg = MonoOutputPanel{};
            pg.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            slot.config.outputPanel = pg;

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
                slot.config.outputPanel = MonoOutputPanel{oldGain};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            KickGeneratorParams inst;
            inst.kickModel = readFloat("kickModel", 0.0f);
            inst.kickPitch = readFloat("kickPitch", 0.55f);
            inst.kickPunch = readFloat("kickPunch", 0.60f);
            inst.kickDecay = readFloat("kickDecay", 0.50f);
            inst.kickClick = readFloat("kickClick", 0.35f);
            inst.kickTone = readFloat("kickTone", 0.50f);
            inst.kickVelocity = readFloat("kickVelocity", 1.0f);
            inst.kickKeyTrack = readFloat("kickKeyTrack", 1.0f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* KickGeneratorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<KickProcessor>();
}

DeviceNodeKind KickGeneratorDeviceType::kind() const noexcept { return DeviceNodeKind::KickGenerator; }

uint16_t KickGeneratorDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto k = [&](std::string_view n, KickParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = k("kickModel", KickParam::Model); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickPitch", KickParam::Pitch); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickPunch", KickParam::Punch); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickDecay", KickParam::Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickClick", KickParam::Click); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickTone", KickParam::Tone); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickVelocity", KickParam::Velocity); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = k("kickKeyTrack", KickParam::KeyTrack); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view KickGeneratorDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<KickParam>(localId)) {
    case KickParam::Model: return "kickModel";
    case KickParam::Pitch: return "kickPitch";
    case KickParam::Punch: return "kickPunch";
    case KickParam::Decay: return "kickDecay";
    case KickParam::Click: return "kickClick";
    case KickParam::Tone: return "kickTone";
    case KickParam::Velocity: return "kickVelocity";
    case KickParam::KeyTrack: return "kickKeyTrack";
    default: return "";
    }
}

std::span<const ParamDescriptor> KickGeneratorDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(KickParam::Model), "kickModel", "Model", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::Pitch), "kickPitch", "Pitch", 0.55f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::Punch), "kickPunch", "Punch", 0.60f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::Decay), "kickDecay", "Decay", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::Click), "kickClick", "Click", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::Tone), "kickTone", "Tone", 0.50f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::Velocity), "kickVelocity", "Velocity", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(KickParam::KeyTrack), "kickKeyTrack", "Key Track", 1.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool KickGeneratorDeviceType::usesDspAutomationSubBlocks() const noexcept {
    return false;
}

} // namespace audioapp
