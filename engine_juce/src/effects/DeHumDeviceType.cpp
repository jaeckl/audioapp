#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DeHumDeviceType.hpp"
#include "audioapp/effects/DeHumParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/DeHumProcessor.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {

DeviceSlot DeHumDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DeHumParams instance;
    instance.mainsFreq = 0.0;
    instance.depth = 0.7;
    instance.harmonics = 0.4;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DeHumDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DeHumParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DeHumParam>(id);
    switch (localId) {
    case DeHumParam::MainsFreq:
        instance.mainsFreq = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeHumParam::Depth:
        instance.depth = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeHumParam::Harmonics:
        instance.harmonics = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DeHumDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> DeHumDeviceType::modulatableParams() const {
    return {"gain", "pan", "humMains", "humDepth", "humHarmonics"};
}

void DeHumDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::DeHum;
    const auto& inst = std::get<DeHumParams>(slot.config.instance);
    DeHumParamsPlayback p;
    p.mainsFreq = static_cast<float>(inst.mainsFreq);
    p.depth = static_cast<float>(inst.depth);
    p.harmonics = static_cast<float>(inst.harmonics);
    p.inputGain = 1.0f;
    out.params = p;
}

bool DeHumDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var DeHumDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DeHumParams>(slot.config.instance);
    parameters->setProperty("mainsFreq", inst.mainsFreq);
    parameters->setProperty("depth", inst.depth);
    parameters->setProperty("harmonics", inst.harmonics);

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

DeviceSlot DeHumDeviceType::varToSlot(const juce::var& obj) const {
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

            DeHumParams inst;
            inst.mainsFreq = p->getProperty("mainsFreq").toString().getDoubleValue();
            inst.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.harmonics = p->getProperty("harmonics").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* DeHumDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DeHumProcessor>();
}

DeviceNodeKind DeHumDeviceType::kind() const noexcept { return DeviceNodeKind::DeHum; }

uint16_t DeHumDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "humMains") return static_cast<uint16_t>(DeHumParam::MainsFreq);
    if (name == "humDepth") return static_cast<uint16_t>(DeHumParam::Depth);
    if (name == "humHarmonics") return static_cast<uint16_t>(DeHumParam::Harmonics);
    return static_cast<uint16_t>(-1);
}

std::string_view DeHumDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DeHumParam>(localId)) {
    case DeHumParam::MainsFreq: return "humMains";
    case DeHumParam::Depth: return "humDepth";
    case DeHumParam::Harmonics: return "humHarmonics";
    default: return "";
    }
}

std::span<const ParamDescriptor> DeHumDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DeHumParam::MainsFreq), "humMains", "Mains", 0.0f, 0.0f, 1.0f, true, true,
         ParameterUpdateRate::Discrete},
        {static_cast<uint16_t>(DeHumParam::Depth), "humDepth", "Depth", 0.7f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeHumParam::Harmonics), "humHarmonics", "Harmonics", 0.4f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DeHumDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
