#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/CymbalGenerator.hpp"

namespace audioapp {

class CymbalProcessor : public DeviceProcessor {
    CymbalGeneratorRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::CymbalGenerator; }

    CymbalGeneratorRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp