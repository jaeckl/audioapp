#include "audioapp/devices/ResonatorBankDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ResonatorBankModel.hpp"
#include "audioapp/devices/processors/ResonatorBankProcessor.hpp"

#include <algorithm>

namespace audioapp {
namespace {

float readFloat(const juce::DynamicObject* object, const char* key, float fallback) {
    const auto value = object->getProperty(key);
    return value.isDouble() || value.isInt() || value.isInt64()
        ? static_cast<float>(static_cast<double>(value))
        : fallback;
}

} // namespace

std::string ResonatorBankDeviceType::typeId() const { return device_types::kResonatorBank; }

DeviceSlot ResonatorBankDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = ResonatorBankModel{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    return slot;
}

DeviceParameterResult ResonatorBankDeviceType::setParameter(DeviceSlot& slot,
                                                            std::string_view parameterId,
                                                            float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    const auto id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) return result;
    auto& model = std::get<ResonatorBankModel>(slot.config.instance);
    const float v = std::clamp(value, 0.0f, 1.0f);
    switch (static_cast<ResonatorBankParam>(id)) {
    case ResonatorBankParam::Root: model.resRoot = v; break;
    case ResonatorBankParam::Spread: model.resSpread = v; break;
    case ResonatorBankParam::Decay: model.resDecay = v; break;
    case ResonatorBankParam::Damping: model.resDamping = v; break;
    case ResonatorBankParam::Color: model.resColor = v; break;
    case ResonatorBankParam::Width: model.resWidth = v; break;
    case ResonatorBankParam::Mix: model.resMix = v; break;
    }
    result.handled = true;
    return result;
}

bool ResonatorBankDeviceType::setStringParameter(DeviceSlot&, std::string_view,
                                                 const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ResonatorBankDeviceType::modulatableParams() const {
    return {"gain", "pan", "resRoot", "resSpread", "resDecay", "resDamping",
            "resColor", "resWidth", "resMix"};
}

void ResonatorBankDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::ResonatorBank;
    out.params = std::get<ResonatorBankModel>(slot.config.instance).toPlaybackParams();
}

bool ResonatorBankDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot&) const {
    return false;
}

juce::var ResonatorBankDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& model = std::get<ResonatorBankModel>(slot.config.instance);
    auto* params = new juce::DynamicObject();
    params->setProperty("resRoot", model.resRoot);
    params->setProperty("resSpread", model.resSpread);
    params->setProperty("resDecay", model.resDecay);
    params->setProperty("resDamping", model.resDamping);
    params->setProperty("resColor", model.resColor);
    params->setProperty("resWidth", model.resWidth);
    params->setProperty("resMix", model.resMix);

    auto* input = new juce::DynamicObject();
    input->setProperty("type", "empty");
    auto* output = new juce::DynamicObject();
    const auto panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    output->setProperty("type", "stereo");
    output->setProperty("gain", panel.gain);
    output->setProperty("pan", panel.pan);
    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("inputPanel", juce::var(input));
    object->setProperty("outputPanel", juce::var(output));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(params));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot ResonatorBankDeviceType::varToSlot(const juce::var& value) const {
    auto slot = createDefault("");
    const auto* object = value.getDynamicObject();
    if (object == nullptr) return slot;
    slot.id = object->getProperty("id").toString().toStdString();
    slot.config.typeId = typeId();
    const auto bypass = object->getProperty("bypass");
    slot.config.bypassed = (bypass.isDouble() || bypass.isInt()) && static_cast<double>(bypass) >= 0.5;

    if (const auto* output = object->getProperty("outputPanel").getDynamicObject()) {
        slot.config.outputPanel = StereoOutputPanel{
            readFloat(output, "gain", 1.0f), readFloat(output, "pan", 0.5f)};
    }
    if (const auto* params = object->getProperty("parameters").getDynamicObject()) {
        ResonatorBankModel model;
        model.resRoot = readFloat(params, "resRoot", model.resRoot);
        model.resSpread = readFloat(params, "resSpread", model.resSpread);
        model.resDecay = readFloat(params, "resDecay", model.resDecay);
        model.resDamping = readFloat(params, "resDamping", model.resDamping);
        model.resColor = readFloat(params, "resColor", model.resColor);
        model.resWidth = readFloat(params, "resWidth", model.resWidth);
        model.resMix = readFloat(params, "resMix", model.resMix);
        slot.config.instance = model;
    }
    return slot;
}

DeviceProcessor* ResonatorBankDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ResonatorBankProcessor>();
}

DeviceNodeKind ResonatorBankDeviceType::kind() const noexcept { return DeviceNodeKind::ResonatorBank; }

uint16_t ResonatorBankDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "resRoot") return static_cast<uint16_t>(ResonatorBankParam::Root);
    if (name == "resSpread") return static_cast<uint16_t>(ResonatorBankParam::Spread);
    if (name == "resDecay") return static_cast<uint16_t>(ResonatorBankParam::Decay);
    if (name == "resDamping") return static_cast<uint16_t>(ResonatorBankParam::Damping);
    if (name == "resColor") return static_cast<uint16_t>(ResonatorBankParam::Color);
    if (name == "resWidth") return static_cast<uint16_t>(ResonatorBankParam::Width);
    if (name == "resMix") return static_cast<uint16_t>(ResonatorBankParam::Mix);
    return static_cast<uint16_t>(-1);
}

std::string_view ResonatorBankDeviceType::paramIdToString(uint16_t id) const noexcept {
    switch (static_cast<ResonatorBankParam>(id)) {
    case ResonatorBankParam::Root: return "resRoot";
    case ResonatorBankParam::Spread: return "resSpread";
    case ResonatorBankParam::Decay: return "resDecay";
    case ResonatorBankParam::Damping: return "resDamping";
    case ResonatorBankParam::Color: return "resColor";
    case ResonatorBankParam::Width: return "resWidth";
    case ResonatorBankParam::Mix: return "resMix";
    }
    return "";
}

std::span<const ParamDescriptor> ResonatorBankDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor params[] = {
        {0, "resRoot", "Root", 0.5f, 0.0f, 1.0f, true, true},
        {1, "resSpread", "Spread", 0.5f, 0.0f, 1.0f, true, true},
        {2, "resDecay", "Decay", 0.55f, 0.0f, 1.0f, true, true},
        {3, "resDamping", "Damping", 0.35f, 0.0f, 1.0f, true, true},
        {4, "resColor", "Color", 0.5f, 0.0f, 1.0f, true, true},
        {5, "resWidth", "Width", 0.5f, 0.0f, 1.0f, true, true},
        {6, "resMix", "Mix", 0.5f, 0.0f, 1.0f, true, true},
    };
    return params;
}

} // namespace audioapp
