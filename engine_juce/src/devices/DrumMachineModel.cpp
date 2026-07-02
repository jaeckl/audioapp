#include "audioapp/devices/instances/DrumMachineModel.hpp"
#include "audioapp/devices/DeviceSlot.hpp"

namespace audioapp {

DrumMachineModel::DrumMachineModel(const DrumMachineModel& other) {
    *this = other;
}

DrumMachineModel& DrumMachineModel::operator=(const DrumMachineModel& other) {
    if (this == &other) return *this;
    for (int i = 0; i < kMidiNoteCount; ++i) {
        const auto& source = other.pads[static_cast<size_t>(i)];
        auto& destination = pads[static_cast<size_t>(i)];
        destination.note = source.note;
        destination.name = source.name;
        destination.gain = source.gain;
        destination.pan = source.pan;
        destination.muted = source.muted;
        destination.solo = source.solo;
        destination.chokeGroup = source.chokeGroup;
        destination.devices.clear();
        destination.devices.reserve(source.devices.size());
        for (const auto& device : source.devices) {
            destination.devices.push_back(device != nullptr
                ? std::make_shared<DeviceSlot>(*device)
                : nullptr);
        }
    }
    return *this;
}

} // namespace audioapp
