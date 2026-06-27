#include "audioapp/devices/TrackGainDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/TrackGainProcessor.hpp"

#include <juce_core/juce_core.h>
#include <algorithm>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string TrackGainDeviceType::typeId() const {
    return device_types::kTrackGain;
}

DeviceSlot TrackGainDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = TrackGainParams{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = MonoOutputPanel{};
    slot.config.bypassed = false;  // TrackGain cannot be bypassed
    return slot;
}

juce::var TrackGainDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    parameters->setProperty("gain", static_cast<double>(
        std::get<MonoOutputPanel>(slot.config.outputPanel).gain));

    auto* outputPanelObj = new juce::DynamicObject();
    outputPanelObj->setProperty("type", "mono");
    outputPanelObj->setProperty("gain", static_cast<double>(
        std::get<MonoOutputPanel>(slot.config.outputPanel).gain));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("outputPanel", juce::var(outputPanelObj));
    return juce::var(object);
}

DeviceSlot TrackGainDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();
        const auto params = object->getProperty("parameters");
        auto readRootFloat = [&](const char* key, float fallback) -> float {
            const auto v = object->getProperty(key);
            if (v.isDouble() || v.isInt() || v.isInt64())
                return static_cast<float>(static_cast<double>(v));
            return fallback;
        };

        // Read outputPanel (new format) with legacy fallback
        const auto outputPanelVar = object->getProperty("outputPanel");
        float gain = 1.0f;  // fallback to legacy
        if (const auto* op = outputPanelVar.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = op->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            gain = readFloat("gain", 1.0f);
        }
        slot.config.outputPanel = MonoOutputPanel{gain};

        slot.config.instance = TrackGainParams{};
        slot.config.inputPanel = EmptyPanel{};
        slot.config.bypassed = false;
    }
    return slot;
}

DeviceParameterResult TrackGainDeviceType::setParameter(DeviceSlot& slot,
                                                        std::string_view parameterId,
                                                        float value) const {
    DeviceParameterResult result;
    const uint16_t id = paramIdFromString(parameterId);
    switch (static_cast<TrackGainParam>(id)) {
    case TrackGainParam::Gain:
    case TrackGainParam::Pan:
        if (device_strip::setStripParameter(slot, parameterId, value)) {
            result.handled = true;
        }
        return result;
    default:
        return result;
    }
}

bool TrackGainDeviceType::setStringParameter(DeviceSlot&,
                                             std::string_view,
                                             const std::string&,
                                             const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> TrackGainDeviceType::modulatableParams() const {
    return {"gain"};
}

void TrackGainDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                            const PlaybackBuildContext&,
                                            DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::TrackGain;
    out.params = TrackGainParams{};
    // Gain is read from outputPanel by the caller (it applies at the
    // mixer/device-chain level, not inside TrackGainParams).
    static_cast<void>(slot);
}

bool TrackGainDeviceType::buildLiveInstrument(const DeviceSlot&,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot&) const {
    return false;
}

DeviceProcessor* TrackGainDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<TrackGainProcessor>();
}

DeviceNodeKind TrackGainDeviceType::kind() const noexcept { return DeviceNodeKind::TrackGain; }

uint16_t TrackGainDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "gain") return static_cast<uint16_t>(TrackGainParam::Gain);
    if (name == "pan") return static_cast<uint16_t>(TrackGainParam::Pan);
    return static_cast<uint16_t>(-1);
}

std::string_view TrackGainDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<TrackGainParam>(localId)) {
    case TrackGainParam::Gain: return "gain";
    case TrackGainParam::Pan: return "pan";
    default: return "";
    }
}

std::span<const ParamDescriptor> TrackGainDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(TrackGainParam::Gain), "gain", "Gain", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(TrackGainParam::Pan), "pan", "Pan", 0.5f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool TrackGainDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
