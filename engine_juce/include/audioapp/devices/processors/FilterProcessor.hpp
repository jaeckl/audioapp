#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class FilterProcessor : public DeviceProcessor {
    FilterRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Filter; }

    FilterRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp