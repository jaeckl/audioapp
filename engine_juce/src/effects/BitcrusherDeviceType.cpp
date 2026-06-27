#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/BitcrusherDeviceType.hpp"
#include "audioapp/effects/BitcrusherParams.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/BitcrusherProcessor.hpp"

namespace audioapp {

DeviceSlot BitcrusherDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    BitcrusherParams instance;
    instance.rate = 0.5;
    instance.bits = 8.0;
    instance.mix = 0.5;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult BitcrusherDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<BitcrusherParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<BitcrusherParam>(id);
    switch (localId) {
    case BitcrusherParam::Rate:
        instance.rate = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    case BitcrusherParam::Bits:
        instance.bits = juce::jlimit(1.0, 16.0, static_cast<double>(value));
        break;
    case BitcrusherParam::Mix:
        instance.mix = juce::jlimit(0.0, 1.0, static_cast<double>(value));
        break;
    default:
        return result;
    }
    result.handled = true;
    return result;
}

bool BitcrusherDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> BitcrusherDeviceType::modulatableParams() const {
    return {"gain", "pan"};
}

void BitcrusherDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Bitcrusher;
    const auto& inst = std::get<BitcrusherParams>(slot.config.instance);
    BitcrusherParamsPlayback p;
    p.rate = static_cast<float>(inst.rate);
    p.bits = static_cast<float>(inst.bits);
    p.mix = static_cast<float>(inst.mix);
    p.inputGain = 1.0f;
    out.params = p;
}

bool BitcrusherDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var BitcrusherDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<BitcrusherParams>(slot.config.instance);
    parameters->setProperty("rate", inst.rate);
    parameters->setProperty("bits", inst.bits);
    parameters->setProperty("mix", inst.mix);

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

DeviceSlot BitcrusherDeviceType::varToSlot(const juce::var& obj) const {
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

            BitcrusherParams inst;
            inst.rate = p->getProperty("rate").toString().getDoubleValue();
            inst.bits = p->getProperty("bits").toString().getDoubleValue();
            inst.mix = p->getProperty("mix").toString().getDoubleValue();
            inst.clamp();
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* BitcrusherDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<BitcrusherProcessor>();
}

DeviceNodeKind BitcrusherDeviceType::kind() const noexcept { return DeviceNodeKind::Bitcrusher; }

uint16_t BitcrusherDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "bcRate") return static_cast<uint16_t>(BitcrusherParam::Rate);
    if (name == "bcBits") return static_cast<uint16_t>(BitcrusherParam::Bits);
    if (name == "bcMix")  return static_cast<uint16_t>(BitcrusherParam::Mix);
    return static_cast<uint16_t>(-1);
}

std::string_view BitcrusherDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<BitcrusherParam>(localId)) {
    case BitcrusherParam::Rate: return "bcRate";
    case BitcrusherParam::Bits: return "bcBits";
    case BitcrusherParam::Mix:  return "bcMix";
    default: return "";
    }
}

std::span<const ParamDescriptor> BitcrusherDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(BitcrusherParam::Rate), "bcRate", "Rate", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Bits), "bcBits", "Bits", 8.0f, 1.0f, 16.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Mix), "bcMix", "Mix", 0.5f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool BitcrusherDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp