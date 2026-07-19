#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DeCracklerDeviceType.hpp"
#include "audioapp/effects/DeCracklerParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/DeCracklerProcessor.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {

DeviceSlot DeCracklerDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DeCracklerParams instance;
    instance.sensitivity = 0.5;
    instance.strength = 0.6;
    instance.width = 0.4;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DeCracklerDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DeCracklerParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DeCracklerParam>(id);
    switch (localId) {
    case DeCracklerParam::Sensitivity:
        instance.sensitivity = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeCracklerParam::Strength:
        instance.strength = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DeCracklerParam::Width:
        instance.width = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DeCracklerDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> DeCracklerDeviceType::modulatableParams() const {
    return {"gain", "pan", "crackSense", "crackStrength", "crackWidth"};
}

void DeCracklerDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::DeCrackler;
    const auto& inst = std::get<DeCracklerParams>(slot.config.instance);
    DeCracklerParamsPlayback p;
    p.sensitivity = static_cast<float>(inst.sensitivity);
    p.strength = static_cast<float>(inst.strength);
    p.width = static_cast<float>(inst.width);
    p.inputGain = 1.0f;
    out.params = p;
}

bool DeCracklerDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var DeCracklerDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DeCracklerParams>(slot.config.instance);
    parameters->setProperty("sensitivity", inst.sensitivity);
    parameters->setProperty("strength", inst.strength);
    parameters->setProperty("width", inst.width);

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

DeviceSlot DeCracklerDeviceType::varToSlot(const juce::var& obj) const {
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

            DeCracklerParams inst;
            inst.sensitivity = p->getProperty("sensitivity").toString().getDoubleValue();
            inst.strength = p->getProperty("strength").toString().getDoubleValue();
            inst.width = p->getProperty("width").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* DeCracklerDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DeCracklerProcessor>();
}

DeviceNodeKind DeCracklerDeviceType::kind() const noexcept { return DeviceNodeKind::DeCrackler; }

uint16_t DeCracklerDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "crackSense") return static_cast<uint16_t>(DeCracklerParam::Sensitivity);
    if (name == "crackStrength") return static_cast<uint16_t>(DeCracklerParam::Strength);
    if (name == "crackWidth") return static_cast<uint16_t>(DeCracklerParam::Width);
    return static_cast<uint16_t>(-1);
}

std::string_view DeCracklerDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DeCracklerParam>(localId)) {
    case DeCracklerParam::Sensitivity: return "crackSense";
    case DeCracklerParam::Strength: return "crackStrength";
    case DeCracklerParam::Width: return "crackWidth";
    default: return "";
    }
}

std::span<const ParamDescriptor> DeCracklerDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DeCracklerParam::Sensitivity), "crackSense", "Sense", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeCracklerParam::Strength), "crackStrength", "Strength", 0.6f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DeCracklerParam::Width), "crackWidth", "Width", 0.4f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DeCracklerDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
