#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class FrequencyShifterProcessor : public DeviceProcessor {
    FrequencyShifterRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::FrequencyShifter; }

    FrequencyShifterRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp