#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/StutterDeviceType.hpp"
#include "audioapp/devices/processors/StutterProcessor.hpp"

namespace audioapp {

namespace {
float readFloatProperty(const juce::DynamicObject* obj, const char* key, float fallback) {
    if (obj == nullptr) return fallback;
    const auto v = obj->getProperty(key);
    if (v.isDouble() || v.isInt() || v.isInt64()) {
        return static_cast<float>(static_cast<double>(v));
    }
    return fallback;
}

void writeOutputPanel(juce::DynamicObject* object, const StereoOutputPanel& panel) {
    auto* outObj = new juce::DynamicObject();
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    outObj->setProperty("outputMix", static_cast<double>(panel.outputMix));
    outObj->setProperty("outputWidth", static_cast<double>(panel.outputWidth));
    object->setProperty("outputPanel", juce::var(outObj));
}
}

DeviceSlot StutterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    StutterParams instance;
    instance.clamp();
    slot.config.instance = instance;
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult StutterDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<StutterParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) return result;

    switch (static_cast<StutterParam>(id)) {
        case StutterParam::Trigger: instance.trigger = juce::jlimit(0.0f, 1.0f, value); break;
        case StutterParam::CaptureMs: instance.captureMs = juce::jlimit(1.0f, 4000.0f, value); break;
        case StutterParam::RateMs: instance.rateMs = juce::jlimit(1.0f, 5000.0f, value); break;
        case StutterParam::WindowMs: instance.windowMs = juce::jlimit(1.0f, 5000.0f, value); break;
        case StutterParam::Position: instance.position = juce::jlimit(0.0f, 1.0f, value); break;
        case StutterParam::Gate: instance.gate = juce::jlimit(0.0f, 1.0f, value); break;
        case StutterParam::FadeMs: instance.fadeMs = juce::jlimit(0.0f, 250.0f, value); break;
        case StutterParam::Direction: instance.direction = juce::jlimit(0.0f, 4.0f, value); break;
        case StutterParam::Mix: instance.mix = juce::jlimit(0.0f, 1.0f, value); break;
        case StutterParam::Duck: instance.duck = juce::jlimit(0.0f, 1.0f, value); break;
        case StutterParam::OutputGain: instance.outputGain = juce::jlimit(0.0f, 2.0f, value); break;
    }
    result.handled = true;
    return result;
}

bool StutterDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> StutterDeviceType::modulatableParams() const {
    return {"gain", "pan", "trigger", "captureMs", "rateMs", "windowMs", "position", "gate", "fadeMs", "direction", "mix", "duck", "outputGain"};
}

void StutterDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Stutter;
    const auto& inst = std::get<StutterParams>(slot.config.instance);
    StutterParamsPlayback p;
    p.trigger = static_cast<float>(inst.trigger);
    p.captureMs = static_cast<float>(inst.captureMs);
    p.rateMs = static_cast<float>(inst.rateMs);
    p.windowMs = static_cast<float>(inst.windowMs);
    p.position = static_cast<float>(inst.position);
    p.gate = static_cast<float>(inst.gate);
    p.fadeMs = static_cast<float>(inst.fadeMs);
    p.direction = static_cast<float>(inst.direction);
    p.mix = static_cast<float>(inst.mix);
    p.duck = static_cast<float>(inst.duck);
    p.outputGain = static_cast<float>(inst.outputGain);
    out.params = p;
}

bool StutterDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const {
    return false;
}

juce::var StutterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<StutterParams>(slot.config.instance);
    parameters->setProperty("trigger", inst.trigger);
    parameters->setProperty("captureMs", inst.captureMs);
    parameters->setProperty("rateMs", inst.rateMs);
    parameters->setProperty("windowMs", inst.windowMs);
    parameters->setProperty("position", inst.position);
    parameters->setProperty("gate", inst.gate);
    parameters->setProperty("fadeMs", inst.fadeMs);
    parameters->setProperty("direction", inst.direction);
    parameters->setProperty("mix", inst.mix);
    parameters->setProperty("duck", inst.duck);
    parameters->setProperty("outputGain", inst.outputGain);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    writeOutputPanel(object, std::get<StereoOutputPanel>(slot.config.outputPanel));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot StutterDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();
        slot.config.inputPanel = EmptyPanel{};

        StereoOutputPanel sp;
        if (const auto* panel = object->getProperty("outputPanel").getDynamicObject()) {
            sp.gain = readFloatProperty(panel, "gain", 1.0f);
            sp.pan = readFloatProperty(panel, "pan", 0.5f);
            sp.outputMix = readFloatProperty(panel, "outputMix", 1.0f);
            sp.outputWidth = readFloatProperty(panel, "outputWidth", 1.0f);
        }
        slot.config.outputPanel = sp;
        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;

        StutterParams inst;
        if (const auto* p = object->getProperty("parameters").getDynamicObject()) {
            inst.trigger = readFloatProperty(p, "trigger", 0.0f);
            inst.captureMs = readFloatProperty(p, "captureMs", 500.0f);
            inst.rateMs = readFloatProperty(p, "rateMs", 125.0f);
            inst.windowMs = readFloatProperty(p, "windowMs", 80.0f);
            inst.position = readFloatProperty(p, "position", 0.0f);
            inst.gate = readFloatProperty(p, "gate", 0.85f);
            inst.fadeMs = readFloatProperty(p, "fadeMs", 3.0f);
            inst.direction = readFloatProperty(p, "direction", 0.0f);
            inst.mix = readFloatProperty(p, "mix", 1.0f);
            inst.duck = readFloatProperty(p, "duck", 0.45f);
            inst.outputGain = readFloatProperty(p, "outputGain", 1.0f);
            inst.clamp();
        }
        slot.config.instance = inst;
    }
    return slot;
}

DeviceProcessor* StutterDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<StutterProcessor>();
}

DeviceNodeKind StutterDeviceType::kind() const noexcept { return DeviceNodeKind::Stutter; }

uint16_t StutterDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "trigger") return static_cast<uint16_t>(StutterParam::Trigger);
    if (name == "captureMs") return static_cast<uint16_t>(StutterParam::CaptureMs);
    if (name == "rateMs") return static_cast<uint16_t>(StutterParam::RateMs);
    if (name == "windowMs") return static_cast<uint16_t>(StutterParam::WindowMs);
    if (name == "position") return static_cast<uint16_t>(StutterParam::Position);
    if (name == "gate") return static_cast<uint16_t>(StutterParam::Gate);
    if (name == "fadeMs") return static_cast<uint16_t>(StutterParam::FadeMs);
    if (name == "direction") return static_cast<uint16_t>(StutterParam::Direction);
    if (name == "mix") return static_cast<uint16_t>(StutterParam::Mix);
    if (name == "duck") return static_cast<uint16_t>(StutterParam::Duck);
    if (name == "outputGain") return static_cast<uint16_t>(StutterParam::OutputGain);
    return static_cast<uint16_t>(-1);
}

std::string_view StutterDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<StutterParam>(localId)) {
        case StutterParam::Trigger: return "trigger";
        case StutterParam::CaptureMs: return "captureMs";
        case StutterParam::RateMs: return "rateMs";
        case StutterParam::WindowMs: return "windowMs";
        case StutterParam::Position: return "position";
        case StutterParam::Gate: return "gate";
        case StutterParam::FadeMs: return "fadeMs";
        case StutterParam::Direction: return "direction";
        case StutterParam::Mix: return "mix";
        case StutterParam::Duck: return "duck";
        case StutterParam::OutputGain: return "outputGain";
    }
    return "";
}

std::span<const ParamDescriptor> StutterDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(StutterParam::Trigger), "trigger", "Trigger", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(StutterParam::CaptureMs), "captureMs", "Capture", 500.0f, 1.0f, 4000.0f, true, true},
        {static_cast<uint16_t>(StutterParam::RateMs), "rateMs", "Rate", 125.0f, 1.0f, 5000.0f, true, true},
        {static_cast<uint16_t>(StutterParam::WindowMs), "windowMs", "Window", 80.0f, 1.0f, 5000.0f, true, true},
        {static_cast<uint16_t>(StutterParam::Position), "position", "Position", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(StutterParam::Gate), "gate", "Gate", 0.85f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(StutterParam::FadeMs), "fadeMs", "Fade", 3.0f, 0.0f, 250.0f, true, true},
        {static_cast<uint16_t>(StutterParam::Direction), "direction", "Direction", 0.0f, 0.0f, 4.0f, true, true},
        {static_cast<uint16_t>(StutterParam::Mix), "mix", "Mix", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(StutterParam::Duck), "duck", "Duck", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(StutterParam::OutputGain), "outputGain", "Output", 1.0f, 0.0f, 2.0f, true, true},
    };
    return kParams;
}

bool StutterDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
