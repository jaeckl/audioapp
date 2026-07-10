#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/ReverbDeviceType.hpp"
#include "audioapp/devices/processors/ReverbProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <algorithm>

namespace audioapp {

namespace {
constexpr const char* kParamNames[] = {
    "modeMorph", "decay", "preDelay", "size", "diffusion",
    "damping", "modulation", "lowCut", "highCut", "ducking", "freeze",
};

float readNumber(const juce::DynamicObject* object, const char* key, float fallback) {
    if (object == nullptr) return fallback;
    const auto value = object->getProperty(key);
    return value.isDouble() || value.isInt() || value.isInt64()
        ? static_cast<float>(static_cast<double>(value)) : fallback;
}
}

DeviceSlot ReverbDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = ReverbParams{};
    slot.config.inputPanel = EmptyPanel{};
    StereoOutputPanel output;
    output.outputMix = 0.35f;
    slot.config.outputPanel = output;
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult ReverbDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    const uint16_t raw = paramIdFromString(parameterId);
    if (raw == static_cast<uint16_t>(-1)) return result;
    auto& params = std::get<ReverbParams>(slot.config.instance);
    const auto normalized = std::clamp(static_cast<double>(value), 0.0, 1.0);
    switch (static_cast<ReverbParam>(raw)) {
    case ReverbParam::ModeMorph: params.modeMorph = std::clamp(static_cast<double>(value), 0.0, 3.0); break;
    case ReverbParam::Decay: params.decay = normalized; break;
    case ReverbParam::PreDelay: params.preDelay = normalized; break;
    case ReverbParam::Size: params.size = normalized; break;
    case ReverbParam::Diffusion: params.diffusion = normalized; break;
    case ReverbParam::Damping: params.damping = normalized; break;
    case ReverbParam::Modulation: params.modulation = normalized; break;
    case ReverbParam::LowCut: params.lowCut = normalized; break;
    case ReverbParam::HighCut: params.highCut = normalized; break;
    case ReverbParam::Ducking: params.ducking = normalized; break;
    case ReverbParam::Freeze: params.freeze = normalized; break;
    }
    result.handled = true;
    return result;
}

bool ReverbDeviceType::setStringParameter(DeviceSlot&, std::string_view,
                                          const std::string&,
                                          const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ReverbDeviceType::modulatableParams() const {
    return {"gain", "pan", "modeMorph", "decay", "preDelay", "size",
            "diffusion", "damping", "modulation", "lowCut", "highCut", "ducking"};
}

void ReverbDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                         const PlaybackBuildContext&,
                                         DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Reverb;
    const auto& source = std::get<ReverbParams>(slot.config.instance);
    ReverbParamsPlayback params;
    params.modeMorph = static_cast<float>(source.modeMorph);
    params.decay = static_cast<float>(source.decay);
    params.preDelay = static_cast<float>(source.preDelay);
    params.size = static_cast<float>(source.size);
    params.diffusion = static_cast<float>(source.diffusion);
    params.damping = static_cast<float>(source.damping);
    params.modulation = static_cast<float>(source.modulation);
    params.lowCut = static_cast<float>(source.lowCut);
    params.highCut = static_cast<float>(source.highCut);
    params.ducking = static_cast<float>(source.ducking);
    params.freeze = static_cast<float>(source.freeze);
    out.params = params;
}

bool ReverbDeviceType::buildLiveInstrument(const DeviceSlot&,
                                           const PlaybackBuildContext&,
                                           LiveInstrumentSnapshot&) const { return false; }

juce::var ReverbDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", std::get<ReverbParams>(slot.config.instance).toJson());
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);

    auto* outputObject = new juce::DynamicObject();
    const auto& output = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outputObject->setProperty("type", "stereo");
    outputObject->setProperty("gain", output.gain);
    outputObject->setProperty("pan", output.pan);
    outputObject->setProperty("outputMix", output.outputMix);
    outputObject->setProperty("outputWidth", output.outputWidth);
    object->setProperty("outputPanel", juce::var(outputObject));

    auto* inputObject = new juce::DynamicObject();
    inputObject->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inputObject));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot ReverbDeviceType::varToSlot(const juce::var& value) const {
    DeviceSlot slot = createDefault("");
    const auto* object = value.getDynamicObject();
    if (object == nullptr) return slot;
    slot.id = object->getProperty("id").toString().toStdString();
    slot.config.typeId = typeId();
    slot.config.inputPanel = EmptyPanel{};

    const auto outputValue = object->getProperty("outputPanel");
    const auto* outputObject = outputValue.getDynamicObject();
    StereoOutputPanel output;
    output.gain = readNumber(outputObject, "gain", 1.0f);
    output.pan = readNumber(outputObject, "pan", 0.5f);
    output.outputMix = readNumber(outputObject, "outputMix", 1.0f);
    output.outputWidth = readNumber(outputObject, "outputWidth", 1.0f);

    const auto parameterValue = object->getProperty("parameters");
    const auto* parameterObject = parameterValue.getDynamicObject();
    if (outputObject == nullptr) {
        output.gain = readNumber(parameterObject, "gain", 1.0f);
        output.pan = readNumber(parameterObject, "pan", 0.5f);
        output.outputMix = readNumber(parameterObject, "outputMix", 1.0f);
        output.outputWidth = readNumber(parameterObject, "outputWidth", 1.0f);
    }
    const bool modern = parameterObject != nullptr && parameterObject->hasProperty("decay");
    if (!modern) {
        const float legacyWet = readNumber(parameterObject, "wetLevel", 0.33f);
        output.outputMix = std::clamp(output.outputMix * legacyWet, 0.0f, 1.0f);
    }
    slot.config.outputPanel = output;
    slot.config.instance = ReverbParams::fromJson(parameterValue);
    const auto bypassValue = object->getProperty("bypass");
    slot.config.bypassed = bypassValue.isDouble() || bypassValue.isInt()
        ? static_cast<double>(bypassValue) >= 0.5 : false;
    return slot;
}

DeviceProcessor* ReverbDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.emplace<ReverbProcessor>();
}

DeviceNodeKind ReverbDeviceType::kind() const noexcept { return DeviceNodeKind::Reverb; }

uint16_t ReverbDeviceType::paramIdFromString(std::string_view name) const noexcept {
    for (uint16_t i = 0; i < static_cast<uint16_t>(std::size(kParamNames)); ++i)
        if (name == kParamNames[i]) return i;
    if (name == "roomSize" || name == "reverbRoomSize") return static_cast<uint16_t>(ReverbParam::Size);
    if (name == "reverbDamping") return static_cast<uint16_t>(ReverbParam::Damping);
    return static_cast<uint16_t>(-1);
}

std::string_view ReverbDeviceType::paramIdToString(uint16_t localId) const noexcept {
    return localId < std::size(kParamNames) ? kParamNames[localId] : "";
}

std::span<const ParamDescriptor> ReverbDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor descriptors[] = {
        {0, "modeMorph", "Mode Morph", 2, 0, 3, true, true},
        {1, "decay", "Decay", .56f, 0, 1, true, true},
        {2, "preDelay", "Pre-delay", .112f, 0, 1, true, true},
        {3, "size", "Size", .64f, 0, 1, true, true},
        {4, "diffusion", "Diffusion", .78f, 0, 1, true, true},
        {5, "damping", "Damping", .68f, 0, 1, true, true},
        {6, "modulation", "Modulation", .18f, 0, 1, true, true},
        {7, "lowCut", "Low Cut", .26f, 0, 1, true, true},
        {8, "highCut", "High Cut", .86f, 0, 1, true, true},
        {9, "ducking", "Ducking", .25f, 0, 1, true, true},
        {10, "freeze", "Freeze", 0, 0, 1, true, true},
    };
    return descriptors;
}

bool ReverbDeviceType::usesDspAutomationSubBlocks() const noexcept { return true; }

} // namespace audioapp
