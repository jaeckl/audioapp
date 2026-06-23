#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/SnareAlgorithm.hpp"

namespace audioapp {

class SnareProcessor : public DeviceProcessor {
    SnareGeneratorRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::SnareGenerator; }

    SnareGeneratorRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp