#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"

namespace audioapp {

class SubtractiveSynthProcessor : public DeviceProcessor {
    SubtractiveSynthRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::SubtractiveSynth; }

    SubtractiveSynthRuntime* runtimePtr() noexcept { return &runtime_; }
};

class BassSynthProcessor : public DeviceProcessor {
    SubtractiveSynthRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::BassSynth; }

    SubtractiveSynthRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp