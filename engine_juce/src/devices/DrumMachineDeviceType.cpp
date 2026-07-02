#include "audioapp/devices/DrumMachineDeviceType.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/processors/DrumMachineProcessor.hpp"

namespace audioapp {

std::string DrumMachineDeviceType::typeId() const { return device_types::kDrumMachine; }

DeviceSlot DrumMachineDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = DrumMachineModel{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    return slot;
}

DeviceParameterResult DrumMachineDeviceType::setParameter(
    DeviceSlot&, std::string_view, float) const { return {}; }

bool DrumMachineDeviceType::setStringParameter(
    DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

void DrumMachineDeviceType::buildPlaybackNode(
    const DeviceSlot&, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::DrumMachine;
    out.params = DrumMachineParams{};
}

juce::var DrumMachineDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    return juce::var(object);
}

DeviceSlot DrumMachineDeviceType::varToSlot(const juce::var& value) const {
    if (const auto* object = value.getDynamicObject()) {
        return createDefault(object->getProperty("id").toString().toStdString());
    }
    return {};
}

DeviceProcessor* DrumMachineDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.emplace<DrumMachineProcessor>();
}

} // namespace audioapp
