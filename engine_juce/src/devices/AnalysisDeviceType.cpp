#include "audioapp/devices/AnalysisDeviceType.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/processors/AnalysisProcessor.hpp"

namespace audioapp {

AnalysisDeviceType::AnalysisDeviceType(const char* typeId, DeviceNodeKind kind) noexcept : typeId_(typeId), kind_(kind) {}
std::string AnalysisDeviceType::typeId() const { return typeId_; }

DeviceSlot AnalysisDeviceType::createDefault(const std::string& id) const {
    DeviceSlot slot; slot.id = id; slot.config.typeId = typeId_;
    slot.config.instance = OscillatorParams{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = kind_ == DeviceNodeKind::StereoImager
        ? OutputPanelParams{StereoOutputPanel{}}
        : OutputPanelParams{EmptyPanel{}};
    return slot;
}

DeviceParameterResult AnalysisDeviceType::setParameter(DeviceSlot& slot, std::string_view id, float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, id, value)) result.handled = true;
    return result;
}
bool AnalysisDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const { return false; }
std::vector<std::string_view> AnalysisDeviceType::modulatableParams() const { return {}; }
void AnalysisDeviceType::buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&, DeviceNodePlayback& out) const { out.kind = kind_; out.params = OscillatorParams{}; }
bool AnalysisDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var AnalysisDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* params = new juce::DynamicObject();
    auto* meters = new juce::DynamicObject(); meters->setProperty("gainReductionDb", 0.0); meters->setProperty("inputLevel", 0.0);
    auto* object = new juce::DynamicObject(); object->setProperty("id", juce::String(slot.id)); object->setProperty("type", juce::String(typeId_));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0); object->setProperty("parameters", juce::var(params)); object->setProperty("meters", juce::var(meters));
    object->setProperty("inputPanel", inputPanelToVar(slot.config.inputPanel)); object->setProperty("outputPanel", outputPanelToVar(slot.config.outputPanel));
    return juce::var(object);
}
DeviceSlot AnalysisDeviceType::varToSlot(const juce::var& value) const {
    auto slot = createDefault(""); if (const auto* object = value.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        const auto bypass = object->getProperty("bypass"); slot.config.bypassed = (bypass.isDouble() || bypass.isInt()) && static_cast<double>(bypass) >= 0.5;
        if (object->getProperty("inputPanel").getDynamicObject() != nullptr)
            slot.config.inputPanel = inputPanelFromVar(object->getProperty("inputPanel"));
        if (object->getProperty("outputPanel").getDynamicObject() != nullptr)
            slot.config.outputPanel = outputPanelFromVar(object->getProperty("outputPanel"));
    } return slot;
}
DeviceProcessor* AnalysisDeviceType::createProcessor(ProcessorArena& arena) const { return arena.template emplace<AnalysisProcessor>(kind_); }
DeviceNodeKind AnalysisDeviceType::kind() const noexcept { return kind_; }
uint16_t AnalysisDeviceType::paramIdFromString(std::string_view) const noexcept { return static_cast<uint16_t>(-1); }
std::string_view AnalysisDeviceType::paramIdToString(uint16_t) const noexcept { return {}; }
std::span<const ParamDescriptor> AnalysisDeviceType::paramDescriptors() const noexcept { return {}; }

}
