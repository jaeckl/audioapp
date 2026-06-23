#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/KickAlgorithm.hpp"

namespace audioapp {

class KickProcessor : public DeviceProcessor {
    KickGeneratorRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::KickGenerator; }

    KickGeneratorRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp