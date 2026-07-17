#include "audioapp/devices/DrumMachineDeviceType.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/processors/DrumMachineProcessor.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"

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
    DeviceSlot& slot, std::string_view parameterId, float value) const {
    DeviceParameterResult result;
    result.handled = device_strip::setStripParameter(slot, parameterId, value);
    return result;
}

bool DrumMachineDeviceType::setStringParameter(
    DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

void DrumMachineDeviceType::buildPlaybackNode(
    const DeviceSlot& slot, const PlaybackBuildContext& context, DeviceNodePlayback& out) const {
    auto playback = std::make_shared<DrumMachinePlayback>();
    const auto& machine = std::get<DrumMachineModel>(slot.config.instance);
    for (int note = 0; note < DrumMachineModel::kMidiNoteCount; ++note) {
        const auto& source = machine.pads[static_cast<size_t>(note)];
        auto& pad = playback->pads[note];
        pad.note = note;
        pad.gain = source.gain;
        pad.pan = source.pan;
        pad.muted = source.muted;
        pad.solo = source.solo;
        pad.chokeGroup = source.chokeGroup;
        if (context.deviceRegistry == nullptr) continue;
        for (const auto& child : source.devices) {
            if (child == nullptr || child->config.typeId == device_types::kDrumMachine ||
                pad.deviceCount >= DrumMachineModel::kMaxDevicesPerPad) continue;
            auto& node = pad.devices[pad.deviceCount++];
            node.deviceId = child->id;
            node.bypassed = child->config.bypassed;
            node.voicePolicy = InstrumentVoicePolicy{1, true};
            std::visit([&](const auto& panel) {
                using T = std::decay_t<decltype(panel)>;
                if constexpr (std::is_same_v<T, MonoOutputPanel>) {
                    node.gain = panel.gain;
                } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
                    node.gain = panel.gain;
                    node.pan = panel.pan;
                    node.outputMix = panel.outputMix;
                    node.outputWidth = panel.outputWidth;
                }
            }, child->config.outputPanel);
            context.deviceRegistry->buildPlaybackNode(*child, context, node);
            // A drum pad selects its child by MIDI note; it must not also
            // transpose a nested sampler. Match live audition by treating the
            // pad note as that sampler's effective root pitch.
            if (node.kind == DeviceNodeKind::Sampler) {
                std::get<SamplerParams>(node.params).rootPitch = note;
            }
        }
    }
    out.kind = DeviceNodeKind::DrumMachine;
    out.params = DrumMachineParams{std::move(playback)};
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
