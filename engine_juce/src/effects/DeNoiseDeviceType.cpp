#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DeNoiseDeviceType.hpp"
#include "audioapp/effects/DeNoiseParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/DeNoiseProcessor.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {

DeviceSlot DeNoiseDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DeNoiseParams instance;
    instance.threshold = 0.35;
    instance.reduction = 0.5;
    instance.smoothing = 0.4;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DeNoiseDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DeNoiseParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DeNoiseParam>(id);
    switch (localId) {
    case DeNoiseParam::Threshold:
        instance.threshold = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeNoiseParam::Reduction:
        instance.reduction = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeNoiseParam::Smoothing:
        instance.smoothing = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DeNoiseDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> DeNoiseDeviceType::modulatableParams() const {
    return {"gain", "pan", "dnThresh", "dnReduce", "dnSmooth"};
}

void DeNoiseDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::DeNoise;
    const auto& inst = std::get<DeNoiseParams>(slot.config.instance);
    DeNoiseParamsPlayback p;
    p.threshold = static_cast<float>(inst.threshold);
    p.reduction = static_cast<float>(inst.reduction);
    p.smoothing = static_cast<float>(inst.smoothing);
    p.inputGain = 1.0f;
    out.params = p;
}

bool DeNoiseDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var DeNoiseDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DeNoiseParams>(slot.config.instance);
    parameters->setProperty("threshold", inst.threshold);
    parameters->setProperty("reduction", inst.reduction);
    parameters->setProperty("smoothing", inst.smoothing);

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

DeviceSlot DeNoiseDeviceType::varToSlot(const juce::var& obj) const {
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

            DeNoiseParams inst;
            inst.threshold = p->getProperty("threshold").toString().getDoubleValue();
            inst.reduction = p->getProperty("reduction").toString().getDoubleValue();
            inst.smoothing = p->getProperty("smoothing").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* DeNoiseDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DeNoiseProcessor>();
}

DeviceNodeKind DeNoiseDeviceType::kind() const noexcept { return DeviceNodeKind::DeNoise; }

uint16_t DeNoiseDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "dnThresh") return static_cast<uint16_t>(DeNoiseParam::Threshold);
    if (name == "dnReduce") return static_cast<uint16_t>(DeNoiseParam::Reduction);
    if (name == "dnSmooth") return static_cast<uint16_t>(DeNoiseParam::Smoothing);
    return static_cast<uint16_t>(-1);
}

std::string_view DeNoiseDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DeNoiseParam>(localId)) {
    case DeNoiseParam::Threshold: return "dnThresh";
    case DeNoiseParam::Reduction: return "dnReduce";
    case DeNoiseParam::Smoothing: return "dnSmooth";
    default: return "";
    }
}

std::span<const ParamDescriptor> DeNoiseDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DeNoiseParam::Threshold), "dnThresh", "Thresh", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeNoiseParam::Reduction), "dnReduce", "Reduce", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeNoiseParam::Smoothing), "dnSmooth", "Smooth", 0.4f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DeNoiseDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
