#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/CrashGenerator.hpp"

namespace audioapp {

class CrashProcessor : public DeviceProcessor {
    CrashGeneratorRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::CrashGenerator; }

    CrashGeneratorRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp