#pragma once

#include <array>
#include <memory>
#include <string>
#include <vector>

namespace audioapp {

struct DeviceSlot;

struct DrumPadModel {
    int note = 36;
    std::string name;
    float gain = 1.0f;
    float pan = 0.5f;
    bool muted = false;
    bool solo = false;
    int chokeGroup = 0;
    std::vector<std::shared_ptr<DeviceSlot>> devices;
};

struct DrumMachineModel {
    static constexpr int kMidiNoteCount = 128;
    static constexpr int kVisiblePadCount = 16;
    static constexpr int kDefaultVisibleNote = 36;
    static constexpr int kMaxDevicesPerPad = 4;
    std::array<DrumPadModel, kMidiNoteCount> pads{};

    DrumMachineModel() {
        for (int note = 0; note < kMidiNoteCount; ++note) {
            pads[static_cast<size_t>(note)].note = note;
        }
    }
    DrumMachineModel(const DrumMachineModel& other);
    DrumMachineModel& operator=(const DrumMachineModel& other);
    DrumMachineModel(DrumMachineModel&&) noexcept = default;
    DrumMachineModel& operator=(DrumMachineModel&&) noexcept = default;
};

} // namespace audioapp
