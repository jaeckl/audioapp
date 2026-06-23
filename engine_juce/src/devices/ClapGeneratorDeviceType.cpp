#include "audioapp/devices/ClapGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/devices/processors/ClapProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string ClapGeneratorDeviceType::typeId() const {
    return device_types::kClapGenerator;
}

DeviceSlot ClapGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = ClapGeneratorParams{};

    slot.config.outputPanel = MonoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult ClapGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                            std::string_view parameterId,
                                                            float value) const {
    DeviceParameterResult result;

    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<ClapGeneratorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "clapBursts") {
        instance.clapBursts = clamped;
    } else if (parameterId == "clapSpread") {
        instance.clapSpread = clamped;
    } else if (parameterId == "clapTone") {
        instance.clapTone = clamped;
    } else if (parameterId == "clapRoom") {
        instance.clapRoom = clamped;
    } else if (parameterId == "clapDecay") {
        instance.clapDecay = clamped;
    } else if (parameterId == "clapVelocity") {
        instance.clapVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool ClapGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                 std::string_view,
                                                 const std::string&,
                                                 const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ClapGeneratorDeviceType::modulatableParams() const {
    return {"gain", "clapBursts", "clapSpread", "clapTone", "clapRoom", "clapDecay",
            "clapVelocity"};
}

void ClapGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    auto params = std::get<ClapGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out.kind = DeviceNodeKind::ClapGenerator;
    out.params = params;
}

bool ClapGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    auto params = std::get<ClapGeneratorParams>(slot.config.instance);
    const auto& panel = std::get<MonoOutputPanel>(slot.config.outputPanel);
    params.gain = panel.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::ClapGenerator;
    out.gain = panel.gain;
    out.clap = params;
    return true;
}

juce::var ClapGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ClapGeneratorParams>(slot.config.instance);
    parameters->setProperty("clapBursts", static_cast<double>(inst.clapBursts));
    parameters->setProperty("clapSpread", static_cast<double>(inst.clapSpread));
    parameters->setProperty("clapTone", static_cast<double>(inst.clapTone));
    parameters->setProperty("clapRoom", static_cast<double>(inst.clapRoom));
    parameters->setProperty("clapDecay", static_cast<double>(inst.clapDecay));
    parameters->setProperty("clapVelocity", static_cast<double>(inst.clapVelocity));

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

DeviceSlot ClapGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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

            ClapGeneratorParams inst;
            inst.clapBursts = readFloat(p, "clapBursts", 0.50f);
            inst.clapSpread = readFloat(p, "clapSpread", 0.45f);
            inst.clapTone = readFloat(p, "clapTone", 0.55f);
            inst.clapRoom = readFloat(p, "clapRoom", 0.50f);
            inst.clapDecay = readFloat(p, "clapDecay", 0.50f);
            inst.clapVelocity = readFloat(p, "clapVelocity", 1.0f);
            slot.config.instance = inst;

        }
    }
    return slot;
}

DeviceProcessor* ClapGeneratorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ClapProcessor>();
}

} // namespace audioapp
