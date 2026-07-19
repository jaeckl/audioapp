#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DeEsserDeviceType.hpp"
#include "audioapp/effects/DeEsserParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/DeEsserProcessor.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {

DeviceSlot DeEsserDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DeEsserParams instance;
    instance.freq = 0.55;
    instance.threshold = 0.45;
    instance.amount = 0.5;
    instance.listen = 0.0;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DeEsserDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DeEsserParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DeEsserParam>(id);
    switch (localId) {
    case DeEsserParam::Freq:
        instance.freq = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeEsserParam::Threshold:
        instance.threshold = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeEsserParam::Amount:
        instance.amount = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeEsserParam::Listen:
        instance.listen = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DeEsserDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> DeEsserDeviceType::modulatableParams() const {
    return {"gain", "pan", "deFreq", "deThresh", "deAmount"};
}

void DeEsserDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::DeEsser;
    const auto& inst = std::get<DeEsserParams>(slot.config.instance);
    DeEsserParamsPlayback p;
    p.freq = static_cast<float>(inst.freq);
    p.threshold = static_cast<float>(inst.threshold);
    p.amount = static_cast<float>(inst.amount);
    p.listen = static_cast<float>(inst.listen);
    p.inputGain = 1.0f;
    out.params = p;
}

bool DeEsserDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var DeEsserDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DeEsserParams>(slot.config.instance);
    parameters->setProperty("freq", inst.freq);
    parameters->setProperty("threshold", inst.threshold);
    parameters->setProperty("amount", inst.amount);
    parameters->setProperty("listen", inst.listen);

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

DeviceSlot DeEsserDeviceType::varToSlot(const juce::var& obj) const {
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
                StereoOutputPanel sp;
                sp.gain = readFloat("gain", 1.0f);
                sp.pan = readFloat("pan", 0.5f);
                sp.outputMix = readFloat("outputMix", 1.0f);
                sp.outputWidth = readFloat("outputWidth", 1.0f);
                slot.config.outputPanel = sp;
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            DeEsserParams inst;
            inst.freq = p->getProperty("freq").toString().getDoubleValue();
            inst.threshold = p->getProperty("threshold").toString().getDoubleValue();
            inst.amount = p->getProperty("amount").toString().getDoubleValue();
            inst.listen = p->getProperty("listen").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* DeEsserDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DeEsserProcessor>();
}

DeviceNodeKind DeEsserDeviceType::kind() const noexcept { return DeviceNodeKind::DeEsser; }

uint16_t DeEsserDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "deFreq") return static_cast<uint16_t>(DeEsserParam::Freq);
    if (name == "deThresh") return static_cast<uint16_t>(DeEsserParam::Threshold);
    if (name == "deAmount") return static_cast<uint16_t>(DeEsserParam::Amount);
    if (name == "deListen") return static_cast<uint16_t>(DeEsserParam::Listen);
    return static_cast<uint16_t>(-1);
}

std::string_view DeEsserDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DeEsserParam>(localId)) {
    case DeEsserParam::Freq: return "deFreq";
    case DeEsserParam::Threshold: return "deThresh";
    case DeEsserParam::Amount: return "deAmount";
    case DeEsserParam::Listen: return "deListen";
    default: return "";
    }
}

std::span<const ParamDescriptor> DeEsserDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DeEsserParam::Freq), "deFreq", "Freq", 0.55f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeEsserParam::Threshold), "deThresh", "Thresh", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeEsserParam::Amount), "deAmount", "Amount", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeEsserParam::Listen), "deListen", "Listen", 0.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DeEsserDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
