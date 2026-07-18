#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DelayDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/DelayParams.hpp"
#include "juce_dsp/juce_dsp.h"
#include "audioapp/devices/processors/DelayProcessor.hpp"

namespace audioapp {

DeviceSlot DelayDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DelayParams instance;
    instance.delayTime = 250.0;
    instance.feedback = 0.4;
    instance.mix = 0.5;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DelayDeviceType::setParameter(DeviceSlot& slot,
                                                    std::string_view parameterId,
                                                    float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DelayParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DelayParam>(id);
    switch (localId) {
    case DelayParam::Time:
        instance.delayTime = juce::jlimit(0.0, 5000.0, static_cast<double>(value));
        break;
    case DelayParam::Feedback:
        instance.feedback = juce::jlimit(0.0, 0.95, static_cast<double>(value));
        break;
    case DelayParam::Mix:
        instance.mix = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DelayParam::TimeMode:
        instance.timeMode = juce::jlimit(0.0, 3.0, std::round(static_cast<double>(value)));
        break;
    case DelayParam::NoteCount:
        instance.noteCount = juce::jlimit(1.0, 8.0, std::round(static_cast<double>(value)));
        break;
    case DelayParam::BlurMode:
        instance.blurMode = juce::jlimit(0.0, 2.0, std::round(static_cast<double>(value)));
        break;
    case DelayParam::BlurAmount:
        instance.blurAmount = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DelayParam::InputDucking:
        instance.inputDucking = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DelayParam::LowCut:
        instance.lowCutHz = juce::jlimit(20.0, juce::jmin(2000.0, instance.highCutHz * 0.5), static_cast<double>(value));
        break;
    case DelayParam::HighCut:
        instance.highCutHz = juce::jlimit(juce::jmax(2000.0, instance.lowCutHz * 2.0), 20000.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DelayDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> DelayDeviceType::modulatableParams() const {
    return {"gain", "pan", "timeMs", "feedback", "mix", "blurAmount",
            "inputDucking", "lowCutHz", "highCutHz"};
}

void DelayDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Delay;
    const auto& inst = std::get<DelayParams>(slot.config.instance);
    DelayParamsPlayback p;
    p.timeMs = static_cast<float>(inst.delayTime);
    p.feedback = static_cast<float>(inst.feedback);
    p.mix = static_cast<float>(inst.mix);
    // Since Delay snapshot doesn't hold inputGain yet, we can default it to 1.0f
    p.inputGain = 1.0f;
    p.timeMode = static_cast<float>(inst.timeMode);
    p.noteCount = static_cast<float>(inst.noteCount);
    p.blurMode = static_cast<float>(inst.blurMode);
    p.blurAmount = static_cast<float>(inst.blurAmount);
    p.inputDucking = static_cast<float>(inst.inputDucking);
    p.lowCutHz = static_cast<float>(inst.lowCutHz);
    p.highCutHz = static_cast<float>(inst.highCutHz);
    out.params = p;
}

bool DelayDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const {
    return false;
}

juce::var DelayDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DelayParams>(slot.config.instance);
    parameters->setProperty("timeMs", inst.delayTime);
    parameters->setProperty("feedback", inst.feedback);
    parameters->setProperty("mix", inst.mix);
    parameters->setProperty("timeMode", inst.timeMode);
    parameters->setProperty("noteCount", inst.noteCount);
    parameters->setProperty("blurMode", inst.blurMode);
    parameters->setProperty("blurAmount", inst.blurAmount);
    parameters->setProperty("inputDucking", inst.inputDucking);
    parameters->setProperty("lowCutHz", inst.lowCutHz);
    parameters->setProperty("highCutHz", inst.highCutHz);

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

DeviceSlot DelayDeviceType::varToSlot(const juce::var& obj) const {
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

            DelayParams inst;
            inst.delayTime = p->getProperty("timeMs").toString().getDoubleValue();
            inst.feedback = p->getProperty("feedback").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.timeMode = readFloat("timeMode", 0.0f);
            inst.noteCount = readFloat("noteCount", 1.0f);
            inst.blurMode = readFloat("blurMode", 0.0f);
            inst.blurAmount = readFloat("blurAmount", 0.5f);
            inst.inputDucking = readFloat("inputDucking", 0.0f);
            inst.lowCutHz = readFloat("lowCutHz", 20.0f);
            inst.highCutHz = readFloat("highCutHz", 20000.0f);
            inst.clamp();
            slot.config.instance = inst;
            
        }
    }
    return slot;
}

DeviceProcessor* DelayDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DelayProcessor>();
}

DeviceNodeKind DelayDeviceType::kind() const noexcept { return DeviceNodeKind::Delay; }

uint16_t DelayDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "timeMs" || name == "delayTimeMs") return static_cast<uint16_t>(DelayParam::Time);
    if (name == "feedback" || name == "delayFeedback") return static_cast<uint16_t>(DelayParam::Feedback);
    if (name == "mix" || name == "delayMix") return static_cast<uint16_t>(DelayParam::Mix);
    if (name == "timeMode") return static_cast<uint16_t>(DelayParam::TimeMode);
    if (name == "noteCount") return static_cast<uint16_t>(DelayParam::NoteCount);
    if (name == "blurMode") return static_cast<uint16_t>(DelayParam::BlurMode);
    if (name == "blurAmount") return static_cast<uint16_t>(DelayParam::BlurAmount);
    if (name == "inputDucking") return static_cast<uint16_t>(DelayParam::InputDucking);
    if (name == "lowCutHz") return static_cast<uint16_t>(DelayParam::LowCut);
    if (name == "highCutHz") return static_cast<uint16_t>(DelayParam::HighCut);
    return static_cast<uint16_t>(-1);
}

std::string_view DelayDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DelayParam>(localId)) {
    case DelayParam::Time: return "delayTimeMs";
    case DelayParam::Feedback: return "delayFeedback";
    case DelayParam::Mix: return "delayMix";
    case DelayParam::TimeMode: return "timeMode";
    case DelayParam::NoteCount: return "noteCount";
    case DelayParam::BlurMode: return "blurMode";
    case DelayParam::BlurAmount: return "blurAmount";
    case DelayParam::InputDucking: return "inputDucking";
    case DelayParam::LowCut: return "lowCutHz";
    case DelayParam::HighCut: return "highCutHz";
    default: return "";
    }
}

std::span<const ParamDescriptor> DelayDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DelayParam::Time), "delayTimeMs", "Time", 250.0f, 0.0f, 5000.0f, true, true},
        {static_cast<uint16_t>(DelayParam::Feedback), "delayFeedback", "Feedback", 0.4f, 0.0f, 0.95f, true, true},
        {static_cast<uint16_t>(DelayParam::Mix), "delayMix", "Mix", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DelayParam::TimeMode), "timeMode", "Time Mode", 0.0f, 0.0f, 3.0f, true, false, ParameterUpdateRate::Discrete},
        {static_cast<uint16_t>(DelayParam::NoteCount), "noteCount", "Notes", 1.0f, 1.0f, 8.0f, true, false, ParameterUpdateRate::Discrete},
        {static_cast<uint16_t>(DelayParam::BlurMode), "blurMode", "Blur", 0.0f, 0.0f, 2.0f, true, false, ParameterUpdateRate::Discrete},
        {static_cast<uint16_t>(DelayParam::BlurAmount), "blurAmount", "Blur Amount", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DelayParam::InputDucking), "inputDucking", "Input Ducking", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DelayParam::LowCut), "lowCutHz", "Low Cut", 20.0f, 20.0f, 2000.0f, true, true},
        {static_cast<uint16_t>(DelayParam::HighCut), "highCutHz", "High Cut", 20000.0f, 2000.0f, 20000.0f, true, true},
    };
    return kParams;
}

bool DelayDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
