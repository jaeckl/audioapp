#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/PhaserDeviceType.hpp"
#include "audioapp/effects/PhaserParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "juce_dsp/juce_dsp.h"
#include "audioapp/devices/processors/PhaserProcessor.hpp"

namespace audioapp {

DeviceSlot PhaserDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    PhaserParams instance;
    instance.depth = 0.5;
    instance.rateHz = 0.8;
    instance.feedback = 0.3;
    instance.centreFrequencyHz = 1000.0;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult PhaserDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<PhaserParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<PhaserParam>(id);
    switch (localId) {
    case PhaserParam::Depth:
        instance.depth = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case PhaserParam::Rate:
        instance.rateHz = juce::jlimit(0.1, 5.0, static_cast<double>(value));
        break;
    case PhaserParam::Feedback:
        instance.feedback = juce::jlimit(0.0, 0.95, static_cast<double>(value));
        break;
    case PhaserParam::CentreFrequency:
        instance.centreFrequencyHz = juce::jlimit(20.0, 20000.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool PhaserDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> PhaserDeviceType::modulatableParams() const {
    return {"gain", "pan", "depth", "rateHz", "feedback", "centreFrequencyHz"};
}

void PhaserDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Phaser;
    const auto& inst = std::get<PhaserParams>(slot.config.instance);
    PhaserParamsPlayback p;
    p.depth = static_cast<float>(inst.depth);
    p.rateHz = static_cast<float>(inst.rateHz);
    p.feedback = static_cast<float>(inst.feedback);
    p.centreFrequencyHz = static_cast<float>(inst.centreFrequencyHz);
    p.inputGain = 1.0f;
    out.params = p;
}

bool PhaserDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var PhaserDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<PhaserParams>(slot.config.instance);
    parameters->setProperty("depth", inst.depth);
    parameters->setProperty("rateHz", inst.rateHz);
    parameters->setProperty("feedback", inst.feedback);
    parameters->setProperty("centreFrequencyHz", inst.centreFrequencyHz);

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

DeviceSlot PhaserDeviceType::varToSlot(const juce::var& obj) const {
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

            PhaserParams inst;
            inst.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.rateHz = p->getProperty("rateHz").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.centreFrequencyHz = p->getProperty("centreFrequencyHz").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
            
        }
    }
    return slot;
}

DeviceProcessor* PhaserDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<PhaserProcessor>();
}

DeviceNodeKind PhaserDeviceType::kind() const noexcept { return DeviceNodeKind::Phaser; }

uint16_t PhaserDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "depth" || name == "phaserDepth") return static_cast<uint16_t>(PhaserParam::Depth);
    if (name == "rateHz" || name == "phaserRateHz") return static_cast<uint16_t>(PhaserParam::Rate);
    if (name == "feedback" || name == "phaserFeedback") return static_cast<uint16_t>(PhaserParam::Feedback);
    if (name == "centreFrequencyHz" || name == "phaserCentreFrequencyHz") return static_cast<uint16_t>(PhaserParam::CentreFrequency);
    return static_cast<uint16_t>(-1);
}

std::string_view PhaserDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<PhaserParam>(localId)) {
    case PhaserParam::Depth: return "phaserDepth";
    case PhaserParam::Rate: return "phaserRateHz";
    case PhaserParam::Feedback: return "phaserFeedback";
    case PhaserParam::CentreFrequency: return "phaserCentreFrequencyHz";
    default: return "";
    }
}

std::span<const ParamDescriptor> PhaserDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(PhaserParam::Depth), "phaserDepth", "Depth", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaserParam::Rate), "phaserRateHz", "Rate", 0.8f, 0.1f, 5.0f, true, true},
        {static_cast<uint16_t>(PhaserParam::Feedback), "phaserFeedback", "Feedback", 0.3f, 0.0f, 0.95f, true, true},
        {static_cast<uint16_t>(PhaserParam::CentreFrequency), "phaserCentreFrequencyHz", "Centre Freq", 1000.0f, 20.0f, 20000.0f, true, true},
    };
    return kParams;
}

bool PhaserDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp