#include "audioapp/devices/OscillatorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"

namespace audioapp {

std::string OscillatorDeviceType::typeId() const {
    return device_types::kOscillator;
}

DeviceSlot OscillatorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = OscillatorInstance{.frequencyHz = 440.0f};
    return slot;
}


DeviceParameterResult OscillatorDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    if (parameterId != "frequency") {
        return result;
    }
    std::get<OscillatorInstance>(slot.instance).frequencyHz = value;
    result.handled = true;
    result.syncActiveFrequency = true;
    return result;
}

bool OscillatorDeviceType::setStringParameter(DeviceSlot&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> OscillatorDeviceType::modulatableParams() const {
    return {"frequency", "gain", "pan"};
}

void OscillatorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    const auto& instance = std::get<OscillatorInstance>(slot.instance);
    out.kind = DeviceNodeKind::Oscillator;
    out.params = OscillatorParams{.frequencyHz = instance.frequencyHz};
}

bool OscillatorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<OscillatorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::Oscillator;
    out.frequencyHz = instance.frequencyHz;
    out.gain = slot.gain;
    return true;
}

juce::var OscillatorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<OscillatorInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("frequency", static_cast<double>(inst.frequencyHz));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot OscillatorDeviceType::varToSlot(const juce::var& obj) const {
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
            OscillatorInstance inst;
            inst.frequencyHz = readFloat("frequency", 440.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
