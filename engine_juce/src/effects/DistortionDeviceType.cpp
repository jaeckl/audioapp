#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DistortionDeviceType.hpp"
#include "audioapp/effects/DistortionParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/DistortionProcessor.hpp"

namespace audioapp {

DeviceSlot DistortionDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DistortionParams instance;
    instance.drive = 0.5;
    instance.tone = 0.5;
    instance.mix = 0.5;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DistortionDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DistortionParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DistortionParam>(id);
    switch (localId) {
    case DistortionParam::Drive:
        instance.drive = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DistortionParam::Tone:
        instance.tone = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DistortionParam::Mix:
        instance.mix = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DistortionDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> DistortionDeviceType::modulatableParams() const {
    return {"gain", "pan"};
}

void DistortionDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Distortion;
    const auto& inst = std::get<DistortionParams>(slot.config.instance);
    DistortionParamsPlayback p;
    p.drive = static_cast<float>(inst.drive);
    p.tone = static_cast<float>(inst.tone);
    p.mix = static_cast<float>(inst.mix);
    p.inputGain = 1.0f;
    out.params = p;
}

bool DistortionDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var DistortionDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DistortionParams>(slot.config.instance);
    parameters->setProperty("drive", inst.drive);
    parameters->setProperty("tone", inst.tone);
    parameters->setProperty("mix", inst.mix);

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

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));

    return juce::var(object);
}

DeviceSlot DistortionDeviceType::varToSlot(const juce::var& obj) const {
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

            DistortionParams inst;
            inst.drive = p->getProperty("drive").toString().getDoubleValue();
            inst.tone = p->getProperty("tone").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* DistortionDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DistortionProcessor>();
}

DeviceNodeKind DistortionDeviceType::kind() const noexcept { return DeviceNodeKind::Distortion; }

uint16_t DistortionDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "distDrive") return static_cast<uint16_t>(DistortionParam::Drive);
    if (name == "distTone")  return static_cast<uint16_t>(DistortionParam::Tone);
    if (name == "distMix")   return static_cast<uint16_t>(DistortionParam::Mix);
    return static_cast<uint16_t>(-1);
}

std::string_view DistortionDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DistortionParam>(localId)) {
    case DistortionParam::Drive: return "distDrive";
    case DistortionParam::Tone:  return "distTone";
    case DistortionParam::Mix:   return "distMix";
    default: return "";
    }
}

std::span<const ParamDescriptor> DistortionDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DistortionParam::Drive), "distDrive", "Drive", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DistortionParam::Tone), "distTone", "Tone", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DistortionParam::Mix), "distMix", "Mix", 0.5f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DistortionDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp