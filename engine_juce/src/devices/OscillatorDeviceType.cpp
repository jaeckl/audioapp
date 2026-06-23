#include "audioapp/devices/OscillatorDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/OscillatorProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string OscillatorDeviceType::typeId() const {
    return device_types::kOscillator;
}

DeviceSlot OscillatorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = OscillatorParams{.frequencyHz = 440.0f};

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
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
    std::get<OscillatorParams>(slot.config.instance).frequencyHz = value;
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
    const auto& instance = std::get<OscillatorParams>(slot.config.instance);
    out.kind = DeviceNodeKind::Oscillator;
    out.params = instance;
}

bool OscillatorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<OscillatorParams>(slot.config.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::Oscillator;
    out.frequencyHz = instance.frequencyHz;
    out.gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    return true;
}

juce::var OscillatorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<OscillatorParams>(slot.config.instance);
    parameters->setProperty("frequency", static_cast<double>(inst.frequencyHz));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot OscillatorDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            StereoOutputPanel sp;
            sp.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            sp.pan = static_cast<float>(static_cast<double>(panel->getProperty("pan")));
            slot.config.outputPanel = sp;

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
                const float oldPan = readFloat("pan", 0.5f);
                slot.config.outputPanel = StereoOutputPanel{oldGain, oldPan};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            OscillatorParams inst;
            inst.frequencyHz = readFloat("frequency", 440.0f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* OscillatorDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<OscillatorProcessor>();
}

} // namespace audioapp
