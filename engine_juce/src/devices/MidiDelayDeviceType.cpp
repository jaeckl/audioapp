#include "audioapp/devices/MidiDelayDeviceType.hpp"

#include "audioapp/MidiDelay.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/processors/RoutingProcessor.hpp"

namespace audioapp {
namespace {
float readFloat(const juce::DynamicObject* object, const char* key, float fallback) {
    const auto value = object->getProperty(key);
    return value.isDouble() || value.isInt() || value.isInt64()
        ? static_cast<float>(static_cast<double>(value)) : fallback;
}
}

std::string MidiDelayDeviceType::typeId() const { return device_types::kMidiDelay; }

DeviceSlot MidiDelayDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = MidiDelayModel{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = RoutingOutputPanel{};
    return slot;
}

DeviceParameterResult MidiDelayDeviceType::setParameter(
    DeviceSlot& slot, std::string_view parameterId, float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& model = std::get<MidiDelayModel>(slot.config.instance);
    if (parameterId == "midiDelayMode") model.mode = std::clamp(value, 0.0f, 1.0f);
    else if (parameterId == "midiDelaySeconds") model.seconds = std::clamp(value, 0.0f, 2.0f);
    else if (parameterId == "midiDelayDivision") model.division = std::clamp(value, 0.0625f, 4.0f);
    else return result;
    result.handled = true;
    return result;
}

bool MidiDelayDeviceType::setStringParameter(DeviceSlot&, std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const { return false; }

std::vector<std::string_view> MidiDelayDeviceType::modulatableParams() const { return {}; }

void MidiDelayDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                            const PlaybackBuildContext&,
                                            DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::MidiDelay;
    out.params = std::get<MidiDelayModel>(slot.config.instance).toPlaybackParams();
}

bool MidiDelayDeviceType::buildLiveInstrument(const DeviceSlot&,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot&) const { return false; }

juce::var MidiDelayDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& model = std::get<MidiDelayModel>(slot.config.instance);
    auto* params = new juce::DynamicObject();
    params->setProperty("midiDelayMode", model.mode);
    params->setProperty("midiDelaySeconds", model.seconds);
    params->setProperty("midiDelayDivision", model.division);
    auto* input = new juce::DynamicObject(); input->setProperty("type", "empty");
    auto* output = new juce::DynamicObject(); output->setProperty("type", "routing");
    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0); meters->setProperty("inputLevel", 0.0);
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

DeviceSlot MidiDelayDeviceType::varToSlot(const juce::var& value) const {
    auto slot = createDefault("");
    const auto* object = value.getDynamicObject();
    if (object == nullptr) return slot;
    slot.id = object->getProperty("id").toString().toStdString();
    const auto bypass = object->getProperty("bypass");
    slot.config.bypassed = (bypass.isDouble() || bypass.isInt()) &&
                           static_cast<double>(bypass) >= 0.5;
    if (const auto* params = object->getProperty("parameters").getDynamicObject()) {
        MidiDelayModel model;
        model.mode = readFloat(params, "midiDelayMode", model.mode);
        model.seconds = readFloat(params, "midiDelaySeconds", model.seconds);
        model.division = readFloat(params, "midiDelayDivision", model.division);
        slot.config.instance = model;
    }
    return slot;
}

DeviceProcessor* MidiDelayDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<RoutingProcessor>(DeviceNodeKind::MidiDelay);
}
DeviceNodeKind MidiDelayDeviceType::kind() const noexcept { return DeviceNodeKind::MidiDelay; }
uint16_t MidiDelayDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "midiDelayMode") return 0;
    if (name == "midiDelaySeconds") return 1;
    if (name == "midiDelayDivision") return 2;
    return static_cast<uint16_t>(-1);
}
std::string_view MidiDelayDeviceType::paramIdToString(uint16_t id) const noexcept {
    if (id == 0) return "midiDelayMode";
    if (id == 1) return "midiDelaySeconds";
    if (id == 2) return "midiDelayDivision";
    return "";
}
std::span<const ParamDescriptor> MidiDelayDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor params[] = {
        {0, "midiDelayMode", "Mode", 0.0f, 0.0f, 1.0f, false, false},
        {1, "midiDelaySeconds", "Seconds", 0.25f, 0.0f, 2.0f, false, false},
        {2, "midiDelayDivision", "Division", 0.5f, 0.0625f, 4.0f, false, false},
    };
    return params;
}

} // namespace audioapp
