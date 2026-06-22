#include "audioapp/devices/ClapGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/ClapGenerator.hpp"

namespace audioapp {

std::string ClapGeneratorDeviceType::typeId() const {
    return device_types::kClapGenerator;
}

DeviceSlot ClapGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = ClapGeneratorParams{};
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

    auto& instance = std::get<ClapGeneratorParams>(slot.instance);
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
    return {"gain", "pan", "clapBursts", "clapSpread", "clapTone", "clapRoom", "clapDecay",
            "clapVelocity"};
}

void ClapGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    auto params = std::get<ClapGeneratorParams>(slot.instance);
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::ClapGenerator;
    out.params = params;
}

bool ClapGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    auto params = std::get<ClapGeneratorParams>(slot.instance);
    params.gain = slot.gain;
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::ClapGenerator;
    out.gain = slot.gain;
    out.clap = params;
    return true;
}

juce::var ClapGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ClapGeneratorParams>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
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
    return juce::var(object);
}

DeviceSlot ClapGeneratorDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            slot.gain = readFloat("gain", 1.0f);
            slot.pan = readFloat("pan", 0.5f);
            slot.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            ClapGeneratorParams inst;
            inst.clapBursts = readFloat("clapBursts", 0.50f);
            inst.clapSpread = readFloat("clapSpread", 0.45f);
            inst.clapTone = readFloat("clapTone", 0.55f);
            inst.clapRoom = readFloat("clapRoom", 0.50f);
            inst.clapDecay = readFloat("clapDecay", 0.50f);
            inst.clapVelocity = readFloat("clapVelocity", 1.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
