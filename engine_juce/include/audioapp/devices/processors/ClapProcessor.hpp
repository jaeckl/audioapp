#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/ClapAlgorithm.hpp"

namespace audioapp {

class ClapProcessor : public DeviceProcessor {
    ClapGeneratorRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::ClapGenerator; }

    ClapGeneratorRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp