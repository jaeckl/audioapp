#include "audioapp/devices/CymbalGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/CymbalGenerator.hpp"
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

    auto& instance = std::get<CymbalGeneratorParams>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "cymbalModel") {
        instance.cymbalModel = clamped;
    } else if (parameterId == "cymbalColor") {
        instance.cymbalColor = clamped;
    } else if (parameterId == "cymbalDecay") {
        instance.cymbalDecay = clamped;
    } else if (parameterId == "cymbalWidth") {
        instance.cymbalWidth = clamped;
    } else if (parameterId == "cymbalVelocity") {
        instance.cymbalVelocity = clamped;
    } else {
        return result;
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
    params.gain = panel.gain;
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

} // namespace audioapp
