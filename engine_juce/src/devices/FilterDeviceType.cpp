#include "audioapp/devices/FilterDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/devices/processors/FilterProcessor.hpp"

#include <algorithm>
#include <cstring>
#include <juce_core/juce_core.h>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string FilterDeviceType::typeId() const { return device_types::kFilter; }

DeviceSlot FilterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = FilterModel{};

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult FilterDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<FilterModel>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    switch (static_cast<FilterParam>(id)) {
    case FilterParam::Cutoff: instance.ffxCutoff = clamped; break;
    case FilterParam::Resonance: instance.ffxResonance = clamped; break;
    case FilterParam::Mode: instance.ffxFilterMode = clamped; break;
    default: return result;
    }
    result.handled = true;
    return result;
}

bool FilterDeviceType::setStringParameter(DeviceSlot&,
                                          std::string_view,
                                          const std::string&,
                                          const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> FilterDeviceType::modulatableParams() const {
    return {"gain", "pan", "ffxCutoff", "ffxResonance", "ffxFilterMode"};
}

void FilterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                         const PlaybackBuildContext&,
                                         DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Filter;
    out.params = std::get<FilterModel>(slot.config.instance).toPlaybackParams();
}

bool FilterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                           const PlaybackBuildContext&,
                                           LiveInstrumentSnapshot&) const {
    return false;
}

juce::var FilterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<FilterModel>(slot.config.instance);
    parameters->setProperty("ffxCutoff", static_cast<double>(inst.ffxCutoff));
    parameters->setProperty("ffxResonance", static_cast<double>(inst.ffxResonance));
    parameters->setProperty("ffxFilterMode", static_cast<double>(inst.ffxFilterMode));

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

DeviceSlot FilterDeviceType::varToSlot(const juce::var& obj) const {
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

            FilterModel inst;
            inst.ffxCutoff = readFloat("ffxCutoff", 0.6f);
            inst.ffxResonance = readFloat("ffxResonance", 0.3f);
            inst.ffxFilterMode = readFloat("ffxFilterMode", 0.0f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* FilterDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<FilterProcessor>();
}

DeviceNodeKind FilterDeviceType::kind() const noexcept { return DeviceNodeKind::Filter; }

uint16_t FilterDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "ffxCutoff") return static_cast<uint16_t>(FilterParam::Cutoff);
    if (name == "ffxResonance") return static_cast<uint16_t>(FilterParam::Resonance);
    if (name == "ffxFilterMode") return static_cast<uint16_t>(FilterParam::Mode);
    return static_cast<uint16_t>(-1);
}

std::string_view FilterDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<FilterParam>(localId)) {
    case FilterParam::Cutoff: return "ffxCutoff";
    case FilterParam::Resonance: return "ffxResonance";
    case FilterParam::Mode: return "ffxFilterMode";
    default: return "";
    }
}

std::span<const ParamDescriptor> FilterDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(FilterParam::Cutoff), "ffxCutoff", "Cutoff", 0.6f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FilterParam::Resonance), "ffxResonance", "Resonance", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FilterParam::Mode), "ffxFilterMode", "Mode", 0.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

} // namespace audioapp