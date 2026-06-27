#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/ReverbDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/ReverbParams.hpp"
#include <juce_core/juce_core.h>
#include "audioapp/devices/processors/ReverbProcessor.hpp"

namespace audioapp {

DeviceSlot ReverbDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    ReverbParams instance;
    instance.roomSize = 0.5;
    instance.damping = 0.5;
    instance.wetLevel = 0.33;
    instance.dryLevel = 0.7;
    instance.width = 1.0;
    instance.freezeMode = false;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult ReverbDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ReverbParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<ReverbParam>(id);
    switch (localId) {
    case ReverbParam::RoomSize:
        instance.roomSize = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case ReverbParam::Damping:
        instance.damping = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case ReverbParam::WetLevel:
        instance.wetLevel = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case ReverbParam::DryLevel:
        instance.dryLevel = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case ReverbParam::Width:
        instance.width = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool ReverbDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ReverbDeviceType::modulatableParams() const {
    return {"gain", "pan", "roomSize", "damping", "wetLevel", "dryLevel", "width"};
}

void ReverbDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Reverb;
    const auto& inst = std::get<ReverbParams>(slot.config.instance);
    ReverbParamsPlayback p;
    p.roomSize = static_cast<float>(inst.roomSize);
    p.damping = static_cast<float>(inst.damping);
    p.wetLevel = static_cast<float>(inst.wetLevel);
    p.dryLevel = static_cast<float>(inst.dryLevel);
    p.width = static_cast<float>(inst.width);
    p.inputGain = 1.0f;
    out.params = p;
}

bool ReverbDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var ReverbDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ReverbParams>(slot.config.instance);
    parameters->setProperty("roomSize", inst.roomSize);
    parameters->setProperty("damping", inst.damping);
    parameters->setProperty("wetLevel", inst.wetLevel);
    parameters->setProperty("dryLevel", inst.dryLevel);
    parameters->setProperty("width", inst.width);
    parameters->setProperty("freezeMode", inst.freezeMode ? 1.0 : 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    outObj->setProperty("outputMix", static_cast<double>(panel.outputMix));
    outObj->setProperty("outputWidth", static_cast<double>(panel.outputWidth));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));

    return juce::var(object);
}

DeviceSlot ReverbDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            auto readPanel = [&](const char* key, float fallback) -> float {
                const auto v = panel->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            StereoOutputPanel sp;
            sp.gain = readPanel("gain", 1.0f);
            sp.pan = readPanel("pan", 0.5f);
            sp.outputMix = readPanel("outputMix", 1.0f);
            sp.outputWidth = readPanel("outputWidth", 1.0f);
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
                StereoOutputPanel sp;
                sp.gain = oldGain;
                sp.pan = oldPan;
                sp.outputMix = readFloat("outputMix", 1.0f);
                sp.outputWidth = readFloat("outputWidth", 1.0f);
                slot.config.outputPanel = sp;
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            ReverbParams inst;
            inst.roomSize = p->getProperty("roomSize").toString().getDoubleValue();
            inst.damping = p->getProperty("damping").toString().getDoubleValue();
            inst.wetLevel = p->getProperty("wetLevel").toString().getDoubleValue();
            inst.dryLevel = p->getProperty("dryLevel").toString().getDoubleValue();
            inst.width = p->getProperty("width").toString().getDoubleValue();
            inst.freezeMode = static_cast<bool>(p->getProperty("freezeMode"));
            inst.clamp();
            slot.config.instance = inst;
            
        }
    }
    return slot;
}

DeviceProcessor* ReverbDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ReverbProcessor>();
}

DeviceNodeKind ReverbDeviceType::kind() const noexcept { return DeviceNodeKind::Reverb; }

uint16_t ReverbDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "roomSize" || name == "reverbRoomSize") return static_cast<uint16_t>(ReverbParam::RoomSize);
    if (name == "damping" || name == "reverbDamping") return static_cast<uint16_t>(ReverbParam::Damping);
    if (name == "wetLevel" || name == "reverbWetLevel") return static_cast<uint16_t>(ReverbParam::WetLevel);
    if (name == "dryLevel" || name == "reverbDryLevel") return static_cast<uint16_t>(ReverbParam::DryLevel);
    if (name == "width" || name == "reverbWidth") return static_cast<uint16_t>(ReverbParam::Width);
    return static_cast<uint16_t>(-1);
}

std::string_view ReverbDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<ReverbParam>(localId)) {
    case ReverbParam::RoomSize: return "reverbRoomSize";
    case ReverbParam::Damping: return "reverbDamping";
    case ReverbParam::WetLevel: return "reverbWetLevel";
    case ReverbParam::DryLevel: return "reverbDryLevel";
    case ReverbParam::Width: return "reverbWidth";
    default: return "";
    }
}

std::span<const ParamDescriptor> ReverbDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(ReverbParam::RoomSize), "reverbRoomSize", "Room Size", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(ReverbParam::Damping), "reverbDamping", "Damping", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(ReverbParam::WetLevel), "reverbWetLevel", "Wet Level", 0.33f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(ReverbParam::DryLevel), "reverbDryLevel", "Dry Level", 0.7f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(ReverbParam::Width), "reverbWidth", "Width", 1.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool ReverbDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp