#include "audioapp/devices/FrequencyShifterDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/devices/processors/FrequencyShifterProcessor.hpp"

#include <algorithm>
#include <cstring>
#include <juce_core/juce_core.h>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string FrequencyShifterDeviceType::typeId() const {
    return device_types::kFrequencyShifter;
}

DeviceSlot FrequencyShifterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = FrequencyShifterModel{};

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult FrequencyShifterDeviceType::setParameter(DeviceSlot& slot,
                                                               std::string_view parameterId,
                                                               float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<FrequencyShifterModel>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    switch (static_cast<FrequencyShifterParam>(id)) {
    case FrequencyShifterParam::Shift: instance.ffxShift = clamped; break;
    default: return result;
    }
    result.handled = true;
    return result;
}

bool FrequencyShifterDeviceType::setStringParameter(DeviceSlot&,
                                                    std::string_view,
                                                    const std::string&,
                                                    const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> FrequencyShifterDeviceType::modulatableParams() const {
    return {"gain", "pan", "ffxShift"};
}

void FrequencyShifterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::FrequencyShifter;
    out.params = std::get<FrequencyShifterModel>(slot.config.instance).toPlaybackParams();
}

bool FrequencyShifterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                                     const PlaybackBuildContext&,
                                                     LiveInstrumentSnapshot&) const {
    return false;
}

juce::var FrequencyShifterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<FrequencyShifterModel>(slot.config.instance);
    parameters->setProperty("ffxShift", static_cast<double>(inst.ffxShift));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));

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
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot FrequencyShifterDeviceType::varToSlot(const juce::var& obj) const {
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

            FrequencyShifterModel inst;
            inst.ffxShift = readFloat("ffxShift", 0.5f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* FrequencyShifterDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<FrequencyShifterProcessor>();
}

DeviceNodeKind FrequencyShifterDeviceType::kind() const noexcept { return DeviceNodeKind::FrequencyShifter; }

uint16_t FrequencyShifterDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "ffxShift") return static_cast<uint16_t>(FrequencyShifterParam::Shift);
    return static_cast<uint16_t>(-1);
}

std::string_view FrequencyShifterDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<FrequencyShifterParam>(localId)) {
    case FrequencyShifterParam::Shift: return "ffxShift";
    default: return "";
    }
}

std::span<const ParamDescriptor> FrequencyShifterDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(FrequencyShifterParam::Shift), "ffxShift", "Shift", 0.5f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

} // namespace audioapp