#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/DynamicsProcessor.hpp"

namespace audioapp {

class ExpanderProcessor : public DeviceProcessor {
    DynamicsRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Expander; }

    DynamicsRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp