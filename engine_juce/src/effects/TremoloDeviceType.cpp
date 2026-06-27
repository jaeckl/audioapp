#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/TremoloDeviceType.hpp"
#include "audioapp/effects/TremoloParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/TremoloProcessor.hpp"

namespace audioapp {

DeviceSlot TremoloDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    TremoloParams instance;
    instance.depth = 0.5;
    instance.rateHz = 5.0;
    instance.shape = 0.0;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult TremoloDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<TremoloParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<TremoloParam>(id);
    switch (localId) {
    case TremoloParam::Depth:
        instance.depth = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case TremoloParam::Rate:
        instance.rateHz = juce::jlimit(0.1, 20.0, static_cast<double>(value));
        break;
    case TremoloParam::Shape:
        instance.shape = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool TremoloDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> TremoloDeviceType::modulatableParams() const {
    return {"gain", "pan"};
}

void TremoloDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Tremolo;
    const auto& inst = std::get<TremoloParams>(slot.config.instance);
    TremoloParamsPlayback p;
    p.depth = static_cast<float>(inst.depth);
    p.rateHz = static_cast<float>(inst.rateHz);
    p.shape = static_cast<float>(inst.shape);
    p.inputGain = 1.0f;
    out.params = p;
}

bool TremoloDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var TremoloDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<TremoloParams>(slot.config.instance);
    parameters->setProperty("depth", inst.depth);
    parameters->setProperty("rateHz", inst.rateHz);
    parameters->setProperty("shape", inst.shape);

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

DeviceSlot TremoloDeviceType::varToSlot(const juce::var& obj) const {
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

            TremoloParams inst;
            inst.depth = p->getProperty("depth").toString().getDoubleValue();
            inst.rateHz = p->getProperty("rateHz").toString().getDoubleValue();
            inst.shape = p->getProperty("shape").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* TremoloDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<TremoloProcessor>();
}

DeviceNodeKind TremoloDeviceType::kind() const noexcept { return DeviceNodeKind::Tremolo; }

uint16_t TremoloDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "tremDepth") return static_cast<uint16_t>(TremoloParam::Depth);
    if (name == "tremRate")  return static_cast<uint16_t>(TremoloParam::Rate);
    if (name == "tremShape") return static_cast<uint16_t>(TremoloParam::Shape);
    return static_cast<uint16_t>(-1);
}

std::string_view TremoloDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<TremoloParam>(localId)) {
    case TremoloParam::Depth: return "tremDepth";
    case TremoloParam::Rate:  return "tremRate";
    case TremoloParam::Shape: return "tremShape";
    default: return "";
    }
}

std::span<const ParamDescriptor> TremoloDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(TremoloParam::Depth), "tremDepth", "Depth", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(TremoloParam::Rate), "tremRate", "Rate", 5.0f, 0.1f, 20.0f, true, true},
        {static_cast<uint16_t>(TremoloParam::Shape), "tremShape", "Shape", 0.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool TremoloDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp