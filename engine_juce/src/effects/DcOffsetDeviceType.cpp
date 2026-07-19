#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DcOffsetDeviceType.hpp"
#include "audioapp/effects/DcOffsetParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/DcOffsetProcessor.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {

DeviceSlot DcOffsetDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    DcOffsetParams instance;
    instance.mode = 1.0;
    instance.amount = 1.0;
    instance.cutoff = 0.3;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DcOffsetDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DcOffsetParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<DcOffsetParam>(id);
    switch (localId) {
    case DcOffsetParam::Mode:
        instance.mode = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DcOffsetParam::Amount:
        instance.amount = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case DcOffsetParam::Cutoff:
        instance.cutoff = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool DcOffsetDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> DcOffsetDeviceType::modulatableParams() const {
    return {"gain", "pan", "dcMode", "dcAmount", "dcCutoff"};
}

void DcOffsetDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::DcOffset;
    const auto& inst = std::get<DcOffsetParams>(slot.config.instance);
    DcOffsetParamsPlayback p;
    p.mode = static_cast<float>(inst.mode);
    p.amount = static_cast<float>(inst.amount);
    p.cutoff = static_cast<float>(inst.cutoff);
    p.inputGain = 1.0f;
    out.params = p;
}

bool DcOffsetDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var DcOffsetDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DcOffsetParams>(slot.config.instance);
    parameters->setProperty("mode", inst.mode);
    parameters->setProperty("amount", inst.amount);
    parameters->setProperty("cutoff", inst.cutoff);

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

DeviceSlot DcOffsetDeviceType::varToSlot(const juce::var& obj) const {
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

            DcOffsetParams inst;
            inst.mode = p->getProperty("mode").toString().getDoubleValue();
            inst.amount = p->getProperty("amount").toString().getDoubleValue();
            inst.cutoff = p->getProperty("cutoff").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* DcOffsetDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DcOffsetProcessor>();
}

DeviceNodeKind DcOffsetDeviceType::kind() const noexcept { return DeviceNodeKind::DcOffset; }

uint16_t DcOffsetDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "dcMode") return static_cast<uint16_t>(DcOffsetParam::Mode);
    if (name == "dcAmount") return static_cast<uint16_t>(DcOffsetParam::Amount);
    if (name == "dcCutoff") return static_cast<uint16_t>(DcOffsetParam::Cutoff);
    return static_cast<uint16_t>(-1);
}

std::string_view DcOffsetDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DcOffsetParam>(localId)) {
    case DcOffsetParam::Mode: return "dcMode";
    case DcOffsetParam::Amount: return "dcAmount";
    case DcOffsetParam::Cutoff: return "dcCutoff";
    default: return "";
    }
}

std::span<const ParamDescriptor> DcOffsetDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DcOffsetParam::Mode), "dcMode", "Mode", 1.0f, 0.0f, 1.0f, true, true,
         ParameterUpdateRate::Discrete},
        {static_cast<uint16_t>(DcOffsetParam::Amount), "dcAmount", "Amount", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DcOffsetParam::Cutoff), "dcCutoff", "Cutoff", 0.3f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DcOffsetDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
