#include "audioapp/devices/RoutingDeviceType.hpp"

#include "audioapp/RoutingDevices.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/processors/RoutingProcessor.hpp"

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

RoutingDeviceType::RoutingDeviceType(const char* typeId, DeviceNodeKind nodeKind) noexcept
    : typeId_(typeId), nodeKind_(nodeKind) {}

std::string RoutingDeviceType::typeId() const { return typeId_; }

bool RoutingDeviceType::hasMix() const noexcept {
    return nodeKind_ == DeviceNodeKind::AudioReceiver;
}

DeviceSlot RoutingDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId_;
    slot.config.instance = RoutingModel{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = RoutingOutputPanel{};
    return slot;
}

DeviceParameterResult RoutingDeviceType::setParameter(DeviceSlot& slot,
                                                       std::string_view parameterId,
                                                       float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& model = std::get<RoutingModel>(slot.config.instance);
    if (parameterId == "routeMix" && hasMix()) {
        model.routeMix = std::clamp(value, 0.0f, 1.0f);
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool RoutingDeviceType::setStringParameter(DeviceSlot& slot, std::string_view parameterId,
                                           const std::string& value, const PlaybackBuildContext&) const {
    if (parameterId != "sourceId") return false;
    std::get<RoutingModel>(slot.config.instance).sourceId = value;
    return true;
}

std::vector<std::string_view> RoutingDeviceType::modulatableParams() const {
    return hasMix() ? std::vector<std::string_view>{"routeMix"}
                    : std::vector<std::string_view>{};
}

void RoutingDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&,
                                          DeviceNodePlayback& out) const {
    out.kind = nodeKind_;
    out.params = std::get<RoutingModel>(slot.config.instance).toPlaybackParams();
}

bool RoutingDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                                            LiveInstrumentSnapshot&) const {
    return false;
}

juce::var RoutingDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& model = std::get<RoutingModel>(slot.config.instance);
    auto* params = new juce::DynamicObject();
    params->setProperty("sourceId", juce::String(model.sourceId));
    params->setProperty("routeMix", model.routeMix);
    auto* input = new juce::DynamicObject();
    input->setProperty("type", "empty");
    auto* output = new juce::DynamicObject();
    output->setProperty("type", "routing");
    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId_));
    object->setProperty("inputPanel", juce::var(input));
    object->setProperty("outputPanel", juce::var(output));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(params));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot RoutingDeviceType::varToSlot(const juce::var& value) const {
    auto slot = createDefault("");
    const auto* object = value.getDynamicObject();
    if (object == nullptr) return slot;
    slot.id = object->getProperty("id").toString().toStdString();
    const auto bypass = object->getProperty("bypass");
    slot.config.bypassed = (bypass.isDouble() || bypass.isInt()) &&
                           static_cast<double>(bypass) >= 0.5;
    if (const auto* params = object->getProperty("parameters").getDynamicObject()) {
        RoutingModel model;
        model.sourceId = params->getProperty("sourceId").toString().toStdString();
        model.routeMix = readFloat(params, "routeMix", model.routeMix);
        slot.config.instance = model;
    }
    return slot;
}

DeviceProcessor* RoutingDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<RoutingProcessor>(nodeKind_);
}

DeviceNodeKind RoutingDeviceType::kind() const noexcept { return nodeKind_; }

uint16_t RoutingDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "routeMix" && hasMix()) return static_cast<uint16_t>(RoutingParam::Mix);
    return static_cast<uint16_t>(-1);
}

std::string_view RoutingDeviceType::paramIdToString(uint16_t id) const noexcept {
    switch (static_cast<RoutingParam>(id)) {
    case RoutingParam::Mix: return hasMix() ? "routeMix" : "";
    }
    return "";
}

std::span<const ParamDescriptor> RoutingDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor audioParams[] = {
        {0, "routeMix", "Mix", 1.0f, 0.0f, 1.0f, true, true},
    };
    return hasMix() ? std::span<const ParamDescriptor>(audioParams)
                    : std::span<const ParamDescriptor>();
}

} // namespace audioapp
