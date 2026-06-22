#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class FourBandEqProcessor : public DeviceProcessor {
    FourBandEqRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::FourBandEq; }

    FourBandEqRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp