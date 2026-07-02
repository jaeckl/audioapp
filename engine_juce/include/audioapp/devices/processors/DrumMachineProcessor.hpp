#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class DrumMachineProcessor final : public DeviceProcessor {
public:
    void process(AudioBlock&, ProcessContext&) noexcept override {}
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::DrumMachine; }
};

} // namespace audioapp
