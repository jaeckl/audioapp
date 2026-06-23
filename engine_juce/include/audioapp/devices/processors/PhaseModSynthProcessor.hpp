#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"

namespace audioapp {

class PhaseModSynthProcessor : public DeviceProcessor {
    PhaseModSynthRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::PhaseModSynth; }

    PhaseModSynthRuntime* runtimePtr() noexcept { return &runtime_; }
};

} // namespace audioapp