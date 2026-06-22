#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

class GateProcessor : public DeviceProcessor {
    DynamicsRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Gate; }

    DynamicsRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp