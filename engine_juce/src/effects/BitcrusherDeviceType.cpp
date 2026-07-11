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
    case BitcrusherParam::Mode: instance.mode = juce::jlimit(0.0, 3.0, static_cast<double>(value)); break;
    case BitcrusherParam::Shape: instance.shape = juce::jlimit(0.0, 3.0, static_cast<double>(value)); break;
    case BitcrusherParam::Jitter: instance.jitter = juce::jlimit(0.0, 1.0, static_cast<double>(value)); break;
    case BitcrusherParam::Drive: instance.drive = juce::jlimit(0.0, 1.0, static_cast<double>(value)); break;
    case BitcrusherParam::DitherMode: instance.ditherMode = juce::jlimit(0.0, 3.0, static_cast<double>(value)); break;
    case BitcrusherParam::DitherAmount: instance.ditherAmount = juce::jlimit(0.0, 1.0, static_cast<double>(value)); break;
    case BitcrusherParam::ClipMode: instance.clipMode = juce::jlimit(0.0, 2.0, static_cast<double>(value)); break;
    case BitcrusherParam::ClipAmount: instance.clipAmount = juce::jlimit(0.0, 1.0, static_cast<double>(value)); break;
    case BitcrusherParam::Filter: instance.filter = juce::jlimit(0.0, 1.0, static_cast<double>(value)); break;
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
    return {"gain", "pan", "bcRate", "bcBits", "bcMix", "bcMode", "bcShape", "bcJitter", "bcDrive",
            "bcDitherMode", "bcDitherAmount", "bcClipMode", "bcClipAmount", "bcFilter"};
}

void BitcrusherDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Bitcrusher;
    const auto& inst = std::get<BitcrusherParams>(slot.config.instance);
    BitcrusherParamsPlayback p;
    p.rate = static_cast<float>(inst.rate);
    p.bits = static_cast<float>(inst.bits);
    p.mix = static_cast<float>(inst.mix);
    p.mode = static_cast<float>(inst.mode); p.shape = static_cast<float>(inst.shape);
    p.jitter = static_cast<float>(inst.jitter); p.drive = static_cast<float>(inst.drive);
    p.ditherMode = static_cast<float>(inst.ditherMode); p.ditherAmount = static_cast<float>(inst.ditherAmount);
    p.clipMode = static_cast<float>(inst.clipMode); p.clipAmount = static_cast<float>(inst.clipAmount);
    p.filter = static_cast<float>(inst.filter);
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
    parameters->setProperty("mode", inst.mode); parameters->setProperty("shape", inst.shape);
    parameters->setProperty("jitter", inst.jitter); parameters->setProperty("drive", inst.drive);
    parameters->setProperty("ditherMode", inst.ditherMode); parameters->setProperty("ditherAmount", inst.ditherAmount);
    parameters->setProperty("clipMode", inst.clipMode); parameters->setProperty("clipAmount", inst.clipAmount);
    parameters->setProperty("filter", inst.filter);

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
            inst.mode = readFloat("mode", static_cast<float>(inst.mode));
            inst.shape = readFloat("shape", static_cast<float>(inst.shape));
            inst.jitter = readFloat("jitter", static_cast<float>(inst.jitter));
            inst.drive = readFloat("drive", static_cast<float>(inst.drive));
            inst.ditherMode = readFloat("ditherMode", static_cast<float>(inst.ditherMode));
            inst.ditherAmount = readFloat("ditherAmount", static_cast<float>(inst.ditherAmount));
            inst.clipMode = readFloat("clipMode", static_cast<float>(inst.clipMode));
            inst.clipAmount = readFloat("clipAmount", static_cast<float>(inst.clipAmount));
            inst.filter = readFloat("filter", static_cast<float>(inst.filter));
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
    if (name == "bcMode") return static_cast<uint16_t>(BitcrusherParam::Mode);
    if (name == "bcShape") return static_cast<uint16_t>(BitcrusherParam::Shape);
    if (name == "bcJitter") return static_cast<uint16_t>(BitcrusherParam::Jitter);
    if (name == "bcDrive") return static_cast<uint16_t>(BitcrusherParam::Drive);
    if (name == "bcDitherMode") return static_cast<uint16_t>(BitcrusherParam::DitherMode);
    if (name == "bcDitherAmount") return static_cast<uint16_t>(BitcrusherParam::DitherAmount);
    if (name == "bcClipMode") return static_cast<uint16_t>(BitcrusherParam::ClipMode);
    if (name == "bcClipAmount") return static_cast<uint16_t>(BitcrusherParam::ClipAmount);
    if (name == "bcFilter") return static_cast<uint16_t>(BitcrusherParam::Filter);
    return static_cast<uint16_t>(-1);
}

std::string_view BitcrusherDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<BitcrusherParam>(localId)) {
    case BitcrusherParam::Rate: return "bcRate";
    case BitcrusherParam::Bits: return "bcBits";
    case BitcrusherParam::Mix:  return "bcMix";
    case BitcrusherParam::Mode: return "bcMode";
    case BitcrusherParam::Shape: return "bcShape";
    case BitcrusherParam::Jitter: return "bcJitter";
    case BitcrusherParam::Drive: return "bcDrive";
    case BitcrusherParam::DitherMode: return "bcDitherMode";
    case BitcrusherParam::DitherAmount: return "bcDitherAmount";
    case BitcrusherParam::ClipMode: return "bcClipMode";
    case BitcrusherParam::ClipAmount: return "bcClipAmount";
    case BitcrusherParam::Filter: return "bcFilter";
    default: return "";
    }
}

std::span<const ParamDescriptor> BitcrusherDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(BitcrusherParam::Rate), "bcRate", "Rate", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Bits), "bcBits", "Bits", 8.0f, 1.0f, 16.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Mix), "bcMix", "Mix", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Mode), "bcMode", "Mode", 0.0f, 0.0f, 3.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Shape), "bcShape", "Shape", 0.0f, 0.0f, 3.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Jitter), "bcJitter", "Jitter", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Drive), "bcDrive", "Drive", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::DitherMode), "bcDitherMode", "Dither Mode", 0.0f, 0.0f, 3.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::DitherAmount), "bcDitherAmount", "Dither", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::ClipMode), "bcClipMode", "Clip Mode", 0.0f, 0.0f, 2.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::ClipAmount), "bcClipAmount", "Clip", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BitcrusherParam::Filter), "bcFilter", "Filter", 1.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool BitcrusherDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
